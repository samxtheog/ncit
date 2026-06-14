const { Router } = require('express');
const multer     = require('multer');
const { protect } = require('../middleware/auth.middleware');
const {
  uploadPdf,
  listPdfs,
  getPdf,
  deletePdf,
  chatWithPdf,
} = require('../controllers/pdf.controller');

const router = Router();

// Store PDF in memory (buffer) — no disk writes needed
const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  fileFilter: (req, file, cb) => {
    const isPdf =
      file.mimetype === 'application/pdf' ||
      file.mimetype === 'application/octet-stream' ||
      file.originalname.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed.'));
    }
  },
});

router.use(protect);

router.get('/',           listPdfs);
router.post('/upload',
  (req, res, next) => {
    upload.single('pdf')(req, res, (err) => {
      if (err) {
        return res.status(422).json({ success: false, message: err.message });
      }
      next();
    });
  },
  uploadPdf,
);
router.get('/:id',        getPdf);
router.delete('/:id',     deletePdf);
router.post('/:id/chat',  chatWithPdf);

module.exports = router;
