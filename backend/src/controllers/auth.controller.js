const { validationResult } = require('express-validator');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/user.model');
const { generateToken } = require('../utils/jwt');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ── Shared helper: format user for API response ───────────────────────────────
const formatUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  faculty: user.faculty || '',
  grade: user.grade || '',
  interests: user.interests || [],
  skills: user.skills || [],
  goal: user.goal || '',
  setupDone: user.setupDone || false,
  xp: user.xp || 0,
  quizCount: user.quizCount || 0,
  lastQuizDate: user.lastQuizDate || '',
  createdAt: user.createdAt,
});

// ── Register ──────────────────────────────────────────────────────────────────
const register = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ success: false, errors: errors.array() });
  }

  const { name, email, password } = req.body;

  try {
    const existing = await User.findOne({ email });
    if (existing) {
      return res
        .status(409)
        .json({ success: false, message: 'Email is already registered.' });
    }

    const user = await User.create({ name, email, password, xp: 2 });
    const token = generateToken(user._id);

    return res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      token,
      user: formatUser(user),
    });
  } catch (error) {
    console.error('Register error:', error.message);
    return res
      .status(500)
      .json({ success: false, message: 'Server error. Please try again.' });
  }
};

// ── Login ─────────────────────────────────────────────────────────────────────
const login = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ success: false, errors: errors.array() });
  }

  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password.' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password.' });
    }

    const token = generateToken(user._id);

    return res.status(200).json({
      success: true,
      message: 'Logged in successfully.',
      token,
      user: formatUser(user),
    });
  } catch (error) {
    console.error('Login error:', error.message);
    return res
      .status(500)
      .json({ success: false, message: 'Server error. Please try again.' });
  }
};

// ── Get current user (protected) ──────────────────────────────────────────────
const getMe = async (req, res) => {
  return res.status(200).json({
    success: true,
    user: formatUser(req.user),
  });
};

// ── Save setup profile (protected) ────────────────────────────────────────────
const saveProfile = async (req, res) => {
  const { faculty, grade, interests, skills, goal } = req.body;

  try {
    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        faculty:   faculty   || '',
        grade:     grade     || '',
        interests: Array.isArray(interests) ? interests : [],
        skills:    Array.isArray(skills)    ? skills    : [],
        goal:      goal      || '',
        setupDone: true,
      },
      { new: true }
    );

    return res.status(200).json({
      success: true,
      message: 'Profile saved.',
      user: formatUser(user),
    });
  } catch (error) {
    console.error('saveProfile error:', error.message);
    return res
      .status(500)
      .json({ success: false, message: 'Server error. Please try again.' });
  }
};

// ── Sync gamification stats (protected) ───────────────────────────────────────
const syncStats = async (req, res) => {
  const { xp, quizCount, lastQuizDate } = req.body;

  try {
    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        xp:           typeof xp === 'number'           ? xp           : 0,
        quizCount:    typeof quizCount === 'number'    ? quizCount    : 0,
        lastQuizDate: typeof lastQuizDate === 'string' ? lastQuizDate : '',
      },
      { new: true }
    );

    return res.status(200).json({
      success: true,
      message: 'Stats synced.',
      user: formatUser(user),
    });
  } catch (error) {
    console.error('syncStats error:', error.message);
    return res
      .status(500)
      .json({ success: false, message: 'Server error. Please try again.' });
  }
};

module.exports = { register, login, getMe, saveProfile, syncStats, googleAuth };

// ── POST /api/auth/google ─────────────────────────────────────────────────────
async function googleAuth(req, res) {
  const { idToken, accessToken, email, name } = req.body;

  try {
    let userEmail, userName;

    if (idToken) {
      // Android / native flow — verify idToken with Google
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      const payload = ticket.getPayload();
      userEmail = payload.email;
      userName  = payload.name;
    } else if (accessToken && email) {
      // Web fallback — verify the accessToken with Google's tokeninfo endpoint
      try {
        const tokenInfoRes = await fetch(
          `https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=${accessToken}`
        );
        const tokenInfo = await tokenInfoRes.json();

        if (!tokenInfoRes.ok || tokenInfo.error) {
          return res.status(401).json({ success: false, message: 'Invalid Google access token.' });
        }

        // Verify the token belongs to our app
        if (tokenInfo.audience !== process.env.GOOGLE_CLIENT_ID &&
            tokenInfo.issued_to !== process.env.GOOGLE_CLIENT_ID) {
          return res.status(401).json({ success: false, message: 'Google token audience mismatch.' });
        }

        userEmail = tokenInfo.email || email;
        userName  = name || userEmail.split('@')[0];
      } catch (fetchErr) {
        console.error('tokeninfo fetch error:', fetchErr.message);
        // If verification fails due to network, fall back to client-provided email
        userEmail = email;
        userName  = name || email.split('@')[0];
      }
    } else {
      return res.status(422).json({ success: false, message: 'idToken or accessToken+email is required.' });
    }

    if (!userEmail) {
      return res.status(400).json({ success: false, message: 'No email found in Google token.' });
    }

    // Find or create user
    let user = await User.findOne({ email: userEmail });
    if (!user) {
      user = await User.create({
        name: userName || userEmail.split('@')[0],
        email: userEmail,
        password: `google_${Date.now()}`,
      });
    }

    const token = generateToken(user._id);
    return res.status(200).json({
      success: true,
      message: 'Logged in with Google.',
      token,
      user: formatUser(user),
    });
  } catch (err) {
    console.error('googleAuth error:', err.message);
    return res.status(401).json({
      success: false,
      message: 'Google Sign-In failed. Please try again.',
    });
  }
}
