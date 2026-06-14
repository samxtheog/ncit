const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema(
  {
    user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name:    { type: String, required: true },
    content: { type: String, required: true, trim: true, maxlength: 500 },
  },
  { timestamps: true }
);

const postSchema = new mongoose.Schema(
  {
    user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name:    { type: String, required: true },   // denormalised for speed
    content: { type: String, required: true, trim: true, maxlength: 1000 },
    tag:     { type: String, default: 'General', trim: true },
    likes:   [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    comments: [commentSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Post', postSchema);
