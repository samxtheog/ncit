const Groq = require('groq-sdk');

let _groq = null;
const getGroq = () => {
  if (!_groq) _groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  return _groq;
};

// In-memory session store keyed by userId (cleared on server restart — fine for now)
const sessions = new Map(); // userId -> ChatMessage[]

const MAX_HISTORY = 20; // messages kept per session

// ── POST /api/chat ────────────────────────────────────────────────────────────
const sendMessage = async (req, res) => {
  const { message } = req.body;
  if (!message?.trim()) {
    return res.status(422).json({ success: false, message: 'Message is required.' });
  }

  const userId = req.user._id.toString();
  if (!sessions.has(userId)) sessions.set(userId, []);
  const history = sessions.get(userId);

  // Build context from user profile
  const { faculty, grade, interests, skills, goal, name } = req.user;
  const profileCtx = [
    name     && `Name: ${name}`,
    faculty  && `Faculty: ${faculty}`,
    grade    && `Grade: ${grade}`,
    interests?.length && `Interests: ${interests.join(', ')}`,
    skills?.length    && `Skills: ${skills.join(', ')}`,
    goal     && `Goal: ${goal}`,
  ].filter(Boolean).join('\n');

  const systemPrompt = `You are SkillBridge AI — a friendly, knowledgeable study assistant for Nepal NEB students.
You help with career advice, study tips, subject questions, and exam preparation.
Keep responses concise, encouraging, and student-friendly.

Student profile:
${profileCtx || 'No profile info available.'}`;

  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.slice(-MAX_HISTORY),
    { role: 'user', content: message.trim() },
  ];

  try {
    const completion = await getGroq().chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages,
      temperature: 0.7,
      max_tokens: 600,
    });

    const reply = completion.choices[0]?.message?.content ?? 'Sorry, I could not respond right now.';

    // Save to session history
    history.push({ role: 'user',      content: message.trim() });
    history.push({ role: 'assistant', content: reply });

    return res.json({ success: true, reply });
  } catch (err) {
    console.error('chat error:', err.message);
    return res.status(500).json({ success: false, message: 'AI error. Please try again.' });
  }
};

// ── DELETE /api/chat ── clear session ─────────────────────────────────────────
const clearChat = (req, res) => {
  const userId = req.user._id.toString();
  sessions.delete(userId);
  return res.json({ success: true, message: 'Chat cleared.' });
};

module.exports = { sendMessage, clearChat };
