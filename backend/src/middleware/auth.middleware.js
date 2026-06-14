const { verifyToken } = require('../utils/jwt');
const User = require('../models/user.model');

/**
 * Protect routes — verifies Bearer JWT in Authorization header.
 * Attaches the authenticated user to req.user.
 */
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res
        .status(401)
        .json({ success: false, message: 'No token provided. Please log in.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);

    // Attach user to request (password excluded via select: false in schema)
    const user = await User.findById(decoded.id);
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'User no longer exists.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res
      .status(401)
      .json({ success: false, message: 'Invalid or expired token.' });
  }
};

module.exports = { protect };
