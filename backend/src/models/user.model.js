const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // never returned in queries by default
    },
    // Setup / onboarding profile
    faculty:   { type: String, default: '' },
    grade:     { type: String, default: '' },
    interests: { type: [String], default: [] },
    skills:    { type: [String], default: [] },
    goal:      { type: String, default: '' },
    setupDone: { type: Boolean, default: false },
    // Gamification stats
    xp:          { type: Number, default: 0 },
    quizCount:   { type: Number, default: 0 },
    lastQuizDate:{ type: String, default: '' },
  },
  {
    timestamps: true, // adds createdAt and updatedAt
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare plain password with hashed password
userSchema.methods.comparePassword = async function (plainPassword) {
  return bcrypt.compare(plainPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
