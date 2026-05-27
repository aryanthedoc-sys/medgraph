const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const { supabaseAdmin } = require('../services/supabase');
const auth = require('../middleware/auth');

// ─── Multer — memory store, 5 MB cap, images only ─────────────────────────────
const ALLOWED_MIME = new Set([
  'image/jpeg', 'image/jpg', 'image/png',
  'image/webp', 'image/heic', 'image/heif',
]);

const _upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    if (!ALLOWED_MIME.has(file.mimetype)) {
      return cb(new Error('Only JPEG, PNG, WebP or HEIC images are allowed'));
    }
    cb(null, true);
  },
});

// Wraps multer so its errors surface as 400s instead of 500s.
function parseUpload(field) {
  const middleware = _upload.single(field);
  return (req, res, next) => {
    middleware(req, res, (err) => {
      if (!err) return next();
      const status = err instanceof multer.MulterError ? 400 : 400;
      return res.status(status).json({ error: err.message });
    });
  };
}

// ─── POST /api/uploads/avatar ─────────────────────────────────────────────────
// Multipart field name: "file"
// Returns: { avatarUrl }
router.post('/avatar', auth, parseUpload('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file received' });

    // Derive extension — normalise jpeg → jpg
    const ext  = req.file.mimetype.split('/')[1].replace('jpeg', 'jpg');
    const storagePath = `${req.user.id}/avatar.${ext}`;

    // Stream buffer into Supabase Storage, overwriting any previous avatar
    const { error: uploadError } = await supabaseAdmin.storage
      .from('avatars')
      .upload(storagePath, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: true,
      });
    if (uploadError) throw uploadError;

    // Public URL + cache-buster so clients see the new image immediately
    const { data: { publicUrl } } = supabaseAdmin.storage
      .from('avatars')
      .getPublicUrl(storagePath);

    const avatarUrl = `${publicUrl}?t=${Date.now()}`;

    // Persist URL in users table
    await supabaseAdmin
      .from('users')
      .update({ avatar_url: avatarUrl })
      .eq('id', req.user.id);

    res.json({ avatarUrl });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
