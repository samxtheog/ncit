const { Router } = require('express');
const { body } = require('express-validator');
const { register, login, getMe, saveProfile, syncStats, googleAuth } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');

const router = Router();

// ── Validation rules ──────────────────────────────────────────────────────────

const registerValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required.')
    .isLength({ min: 2 }).withMessage('Name must be at least 2 characters.'),
  body('email')
    .trim()
    .notEmpty().withMessage('Email is required.')
    .isEmail().withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Password is required.')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters.'),
];

const loginValidation = [
  body('email')
    .trim()
    .notEmpty().withMessage('Email is required.')
    .isEmail().withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Password is required.'),
];

// ── Routes ────────────────────────────────────────────────────────────────────

// POST /api/auth/register
router.post('/register', registerValidation, register);

// POST /api/auth/login
router.post('/login', loginValidation, login);

// GET /api/auth/me  (protected — requires Bearer token)
router.get('/me', protect, getMe);

// POST /api/auth/profile  (protected — save setup profile)
router.post('/profile', protect, saveProfile);

// POST /api/auth/stats  (protected — sync XP/quiz stats)
router.post('/stats', protect, syncStats);

// POST /api/auth/google  (Google Sign-In — no password needed)
router.post('/google', googleAuth);

module.exports = router;
