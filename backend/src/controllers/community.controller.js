const Post = require('../models/post.model');

// ── Helper: format a post for the API response ────────────────────────────────
const fmt = (post, userId) => ({
  id:         post._id,
  userId:     post.user,
  name:       post.name,
  content:    post.content,
  tag:        post.tag,
  likeCount:  post.likes.length,
  likedByMe:  userId ? post.likes.map(String).includes(String(userId)) : false,
  commentCount: post.comments.length,
  comments:   post.comments.map((c) => ({
    id:        c._id,
    userId:    c.user,
    name:      c.name,
    content:   c.content,
    createdAt: c.createdAt,
  })),
  createdAt:  post.createdAt,
});

// ── GET /api/community/posts ──────────────────────────────────────────────────
const getPosts = async (req, res) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(20, parseInt(req.query.limit) || 10);
    const skip  = (page - 1) * limit;

    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Post.countDocuments();

    return res.json({
      success: true,
      posts:   posts.map((p) => fmt(p, req.user?._id)),
      total,
      page,
      pages: Math.ceil(total / limit),
    });
  } catch (err) {
    console.error('getPosts:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── POST /api/community/posts ─────────────────────────────────────────────────
const createPost = async (req, res) => {
  const { content, tag } = req.body;
  if (!content?.trim()) {
    return res.status(422).json({ success: false, message: 'Content is required.' });
  }
  try {
    const post = await Post.create({
      user:    req.user._id,
      name:    req.user.name,
      content: content.trim(),
      tag:     tag?.trim() || 'General',
    });
    return res.status(201).json({ success: true, post: fmt(post, req.user._id) });
  } catch (err) {
    console.error('createPost:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── POST /api/community/posts/:id/like ────────────────────────────────────────
const toggleLike = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found.' });

    const uid      = String(req.user._id);
    const likedIdx = post.likes.map(String).indexOf(uid);

    if (likedIdx === -1) {
      post.likes.push(req.user._id);
    } else {
      post.likes.splice(likedIdx, 1);
    }
    await post.save();

    return res.json({
      success:   true,
      likeCount: post.likes.length,
      likedByMe: likedIdx === -1, // true if we just added
    });
  } catch (err) {
    console.error('toggleLike:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── POST /api/community/posts/:id/comments ────────────────────────────────────
const addComment = async (req, res) => {
  const { content } = req.body;
  if (!content?.trim()) {
    return res.status(422).json({ success: false, message: 'Comment cannot be empty.' });
  }
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found.' });

    post.comments.push({
      user:    req.user._id,
      name:    req.user.name,
      content: content.trim(),
    });
    await post.save();

    const added = post.comments[post.comments.length - 1];
    return res.status(201).json({
      success: true,
      comment: {
        id:        added._id,
        userId:    added.user,
        name:      added.name,
        content:   added.content,
        createdAt: added.createdAt,
      },
    });
  } catch (err) {
    console.error('addComment:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// ── DELETE /api/community/posts/:id ──────────────────────────────────────────
const deletePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found.' });
    if (String(post.user) !== String(req.user._id)) {
      return res.status(403).json({ success: false, message: 'Not your post.' });
    }
    await post.deleteOne();
    return res.json({ success: true, message: 'Post deleted.' });
  } catch (err) {
    console.error('deletePost:', err.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

module.exports = { getPosts, createPost, toggleLike, addComment, deletePost };
