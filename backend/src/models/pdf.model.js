const mongoose = require('mongoose');

const pdfSchema = new mongoose.Schema(
  {
    user:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    filename:    { type: String, required: true },
    originalName:{ type: String, required: true },
    size:        { type: Number, required: true },   // bytes
    pages:       { type: Number, default: 0 },
    text:        { type: String, default: '' },      // extracted text
    // Store chat history per PDF
    messages:    [
      {
        role:    { type: String, enum: ['user', 'assistant'], required: true },
        content: { type: String, required: true },
        at:      { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Pdf', pdfSchema);
