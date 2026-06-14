const { validationResult } = require('express-validator');
const { generateQuiz } = require('../services/groq.service');

/**
 * POST /api/quiz/generate
 * Generates 10 NEB MCQ questions based on user's faculty & grade.
 */
const getQuiz = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ success: false, errors: errors.array() });
  }

  const { faculty, grade } = req.body;

  try {
    const quiz = await generateQuiz({ faculty, grade });
    return res.status(200).json({ success: true, quiz });
  } catch (error) {
    console.error('Quiz generation error:', error.message);

    if (error instanceof SyntaxError) {
      return res.status(500).json({
        success: false,
        message: 'AI returned an unexpected response. Please try again.',
      });
    }

    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate quiz. Please try again.',
    });
  }
};

module.exports = { getQuiz };
