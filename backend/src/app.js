const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes      = require('./routes/auth.routes');
const careerRoutes    = require('./routes/career.routes');
const quizRoutes      = require('./routes/quiz.routes');
const communityRoutes = require('./routes/community.routes');
const pdfRoutes       = require('./routes/pdf.routes');
const chatRoutes      = require('./routes/chat.routes');

const app = express();

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:8080',  // Flutter web fixed port
    /^http:\/\/localhost:\d+$/, // allow any localhost port (Flutter web dev)
  ],
  credentials: true,
}));
app.use(express.json());

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth',       authRoutes);
app.use('/api/career',    careerRoutes);
app.use('/api/quiz',      quizRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/pdf',       pdfRoutes);
app.use('/api/chat',      chatRoutes);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'SkillBridge API is running' });
});

// ── 404 handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

module.exports = app;
