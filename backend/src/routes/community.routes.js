const { Router } = require('express');
const { protect } = require('../middleware/auth.middleware');
const {
  getPosts,
  createPost,
  toggleLike,
  addComment,
  deletePost,
} = require('../controllers/community.controller');

const router = Router();

// All community routes require auth
router.use(protect);

router.get('/posts',                 getPosts);
router.post('/posts',                createPost);
router.post('/posts/:id/like',       toggleLike);
router.post('/posts/:id/comments',   addComment);
router.delete('/posts/:id',          deletePost);

module.exports = router;
