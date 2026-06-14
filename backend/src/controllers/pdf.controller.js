const PDFParser = require('pdf2json');
const Pdf       = require('../models/pdf.model');
const Groq      = require('groq-sdk');

let _groq = null;
const getGroq = () => {
  if (!_groq) _groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  return _groq;
};

// ── Extract plain text from a PDF buffer using pdf2json ───────────────────────
const extractText = (buffer) =>
  new Promise((resolve) => {
    const parser = new PDFParser(null, 1); // 1 = raw text mode

    parser.on('pdfParser_dataReady', (data) => {
      try {
        const pages = data.Pages || [];
        const text = pages
          .map((page) =>
            (page.Texts || [])
              .map((t) =>
                (t.R || []).map((r) => decodeURIComponent(r.T)).join('')
              )
              .join(' ')
          )
          .join('\n\n');
        resolve({ text: text.trim(), pages: pages.length });
      } catch (_) {
        resolve({ text: '', pages: 0 });
      }
    });

    parser.on('pdfParser_dataError', () => resolve({ text: '', pages: 0 }));

    parser.parseBuffer(buffer);
  });

// ── Format doc for API response ───────────────────────────────────────────────
const fmtPdf = (doc) => ({
  id:           doc._id,
  filename:     doc.filename,
  originalName: doc.originalName,
  size:         doc.size,
  pages:        doc.pages,
  hasText:      doc.text.length > 0,
  preview:      doc.text.slice(0, 300),
  messageCount: doc.messages.length,
  createdAt:    doc.createdAt,
});

// ── POST /api/pdf/upload ──────────────────────────────────────────────────────
const uploadPdf = async (req, res) => {
  if (!req.file) {
    return res.status(422).json({ success: false, message: 'No PDF file provided.' });
  }
  try {
    const { text, pages } = await extractText(req.file.buffer);

    const doc = await Pdf.create({
      user:         req.user._id,
      filename:     req.file.originalname,
      originalName: req.file.originalname,
      size:         req.file.size,
      pages,
      text,
    });

    return res.status(201).json({ success: true, pdf: fmtPdf(doc), text: doc.text });
  } catch (err) {
    console.error('uploadPdf:', err.message);
    return res.status(500).json({ success: false, message: 'Failed to process PDF.' });
  }
};

// ── GET /api/pdf ──────────────────────────────────────────────────────────────
const listPdfs = async (req, res) => {
  try {
    const docs = await Pdf.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(20)
      .select('-text -messages');
    return res.json({ success: true, pdfs: docs.map(fmtPdf) });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── GET /api/pdf/:id ──────────────────────────────────────────────────────────
const getPdf = async (req, res) => {
  try {
    const doc = await Pdf.findOne({ _id: req.params.id, user: req.user._id });
    if (!doc) return res.status(404).json({ success: false, message: 'PDF not found.' });
    return res.json({ success: true, pdf: fmtPdf(doc), text: doc.text, messages: doc.messages });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── DELETE /api/pdf/:id ───────────────────────────────────────────────────────
const deletePdf = async (req, res) => {
  try {
    const doc = await Pdf.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!doc) return res.status(404).json({ success: false, message: 'PDF not found.' });
    return res.json({ success: true, message: 'Deleted.' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── POST /api/pdf/:id/chat ────────────────────────────────────────────────────
const chatWithPdf = async (req, res) => {
  const { message } = req.body;
  if (!message?.trim()) {
    return res.status(422).json({ success: false, message: 'Message is required.' });
  }
  try {
    const doc = await Pdf.findOne({ _id: req.params.id, user: req.user._id });
    if (!doc) return res.status(404).json({ success: false, message: 'PDF not found.' });

    // Smart context: use up to 12,000 chars but try to cut at a sentence boundary
    let context = '';
    if (doc.text && doc.text.length > 0) {
      const raw = doc.text.slice(0, 12000);
      // Trim to last full sentence so we don't cut mid-word
      const lastPeriod = Math.max(raw.lastIndexOf('. '), raw.lastIndexOf('.\n'));
      context = lastPeriod > 8000 ? raw.slice(0, lastPeriod + 1) : raw;
    }

    const hasContext = context.length > 0;

    const systemPrompt = hasContext
      ? `You are an expert AI study assistant helping a student understand their uploaded PDF document.

PDF Title: "${doc.originalName}"
PDF Content (extracted text):
---
${context}
---

Your job:
- Answer questions clearly and accurately based on the PDF content above
- If asked to summarize, give a structured summary with key points
- If asked to explain a concept, break it down simply with examples where helpful
- If asked a question not covered in the PDF, say so honestly and answer from general knowledge
- Use bullet points and short paragraphs for readability
- Keep responses focused and student-friendly`
      : `You are a helpful AI study assistant. The uploaded PDF "${doc.originalName}" could not have its text extracted (it may be a scanned image or protected PDF).
Answer the student's questions based on general knowledge about the topic suggested by the filename.
Be honest that you cannot read the actual PDF content.`;

    // Keep last 10 messages for context (5 exchanges)
    const history = doc.messages.slice(-10).map((m) => ({
      role: m.role, content: m.content,
    }));

    const completion = await getGroq().chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: systemPrompt },
        ...history,
        { role: 'user', content: message.trim() },
      ],
      temperature: 0.3,
      max_tokens: 1200,
    });

    const reply = completion.choices[0]?.message?.content ?? 'Sorry, I could not generate a response.';

    doc.messages.push({ role: 'user',      content: message.trim() });
    doc.messages.push({ role: 'assistant', content: reply });
    await doc.save();

    return res.json({ success: true, reply, messageCount: doc.messages.length });
  } catch (err) {
    console.error('chatWithPdf:', err.message);
    return res.status(500).json({ success: false, message: 'AI error. Please try again.' });
  }
};

module.exports = { uploadPdf, listPdfs, getPdf, deletePdf, chatWithPdf };
