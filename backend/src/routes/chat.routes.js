const { Router } = require('express');
const { protect } = require('../middleware/auth.middleware');
const { sendMessage, clearChat } = require('../controllers/chat.controller');

const router = Router();

router.use(protect);

router.post('/',   sendMessage);
router.delete('/', clearChat);

module.exports = router;
