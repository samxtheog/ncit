const { Router } = require('express');
const { body } = require('express-validator');
const { getQuiz } = require('../controllers/quiz.controller');
const { protect } = require('../middleware/auth.middleware');

const router = Router();

// POST /api/quiz/generate  (protected)
router.post(
  '/generate',
  protect,
  [
    body('faculty').optional().trim(),
    body('grade').optional().trim(),
  ],
  getQuiz
);

module.exports = router;
