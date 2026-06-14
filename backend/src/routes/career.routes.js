const { Router } = require('express');
const { body } = require('express-validator');
const { getRoadmap, getLearningPath, getCareerSuggestions, getInterestSuggestions } = require('../controllers/career.controller');
const { protect } = require('../middleware/auth.middleware');

const router = Router();

const roadmapValidation = [
  body('careerTitle').trim().notEmpty().withMessage('Career title is required.'),
  body('faculty').optional().trim(),
  body('grade').optional().trim(),
  body('interests').optional().isArray(),
  body('skills').optional().isArray(),
  body('goal').optional().trim(),
];

// POST /api/career/roadmap  (protected)
router.post('/roadmap', protect, roadmapValidation, getRoadmap);

// POST /api/career/learning-path  (protected)
router.post('/learning-path', protect, getLearningPath);

// POST /api/career/suggestions  (protected)
router.post('/suggestions', protect, getCareerSuggestions);

// POST /api/career/interests  (protected)
router.post('/interests', protect, getInterestSuggestions);

module.exports = router;
