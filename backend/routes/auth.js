const express  = require('express');
const router   = express.Router();
const crypto   = require('crypto');
const multer   = require('multer');
const jwt      = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const {
  sendOTP,
  sendWelcomeDoctor,
  sendProofSubmittedNotification,
} = require('../services/resend');
const auth = require('../middleware/auth');

console.log('RESEND KEY CHECK:', process.env.RESEND_API_KEY ? 'LOADED' : 'MISSING');

// Temporary OTP store: email → { otp, expiresAt, name, userType, ...regFields }
const otpStore = new Map();

// ─── POST /api/auth/send-otp ─────────────────────────────────────────────────
router.post('/send-otp', async (req, res, next) => {
  try {
    const {
      email, name, userType,
      // student fields
      collegeName, collegeCity, collegeState, university, yearOfStudy,
      // doctor fields
      specialty, nmcNumber, yearsExperience,
    } = req.body;

    if (!email || !name) return res.status(400).json({ error: 'email and name required' });
    if (!userType) return res.status(400).json({ error: 'userType required' });

    // Accept any valid email format — no college email restriction
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email address' });
    }

    // Check not already registered
    const { data: existing } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email.toLowerCase())
      .single();
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    otpStore.set(email.toLowerCase(), {
      otp,
      name,
      userType,
      collegeName,
      collegeCity,
      collegeState,
      university,
      yearOfStudy,
      specialty,
      nmcNumber,
      yearsExperience,
      expiresAt: Date.now() + 15 * 60 * 1000, // 15 min
    });

    console.log(`[OTP] Generated for ${email}: ${otp}`);
    await sendOTP(email, otp);

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/auth/verify-otp ───────────────────────────────────────────────
router.post('/verify-otp', async (req, res, next) => {
  try {
    const { email, otp, name: bodyName, role: bodyRole } = req.body;
    console.log('Verify OTP body:', { email, otp: '***', name: bodyName, role: bodyRole });
    const lower = email?.toLowerCase().trim();
    const entry = otpStore.get(lower);

    if (!entry || entry.otp !== otp || Date.now() > entry.expiresAt) {
      return res.status(400).json({ error: 'Invalid or expired code' });
    }
    otpStore.delete(lower);

    const roleMap = {
      'student':      'student_mbbs',
      'student_mbbs': 'student_mbbs',
      'student_bds':  'student_bds',
      'student_bams': 'student_bams',
      'doctor':       'doctor',
    };
    const rawRole  = entry?.userType || bodyRole;
    const safeRole = roleMap[rawRole] || 'student_mbbs';
    const safeName = ((entry?.name || bodyName || '').trim()) || 'User';

    // Check if user already exists in public.users
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id, email, full_name, role, status, is_pro')
      .eq('email', lower)
      .maybeSingle();

    let user = existingUser;

    if (!user) {
      // Minimal insert — only columns guaranteed to exist at registration time.
      // Profile details (college, specialty, mrn, etc.) are filled in during setup.
      const userRow = {
        email:          lower,
        full_name:      safeName,
        role:           safeRole,
        status:         'pending_verification',
        is_pro:         true,
        pro_expires_at: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
      };

      const { data: newUser, error: insertError } = await supabaseAdmin
        .from('users')
        .insert(userRow)
        .select('id, email, full_name, role, status, is_pro')
        .single();

      if (insertError) {
        console.error('User insert error:', JSON.stringify(insertError));
        return res.status(500).json({
          success: false,
          error: insertError.message,
          debug: { code: insertError.code, details: insertError.details },
        });
      }

      user = newUser;
      console.log('New user created with id:', user.id);
    } else {
      console.log('Existing user found with id:', user.id);
    }

    // Generate custom JWT using public.users id
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );
    console.log('JWT generated for user.id:', user.id);

    return res.json({
      success: true,
      ok: true,           // keep ok:true for backward compat
      isNewUser: !existingUser,
      token,
      accessToken: token, // keep accessToken for backward compat
      userId: user.id,    // keep userId for backward compat
      user: {
        id:        user.id,
        email:     user.email,
        full_name: user.full_name,
        role:      user.role,
        status:    user.status,
        is_pro:    user.is_pro,
      },
    });
  } catch (err) {
    console.error('=== VERIFY OTP ERROR ===', err.message);
    return res.status(500).json({
      success: false,
      error: err.message,
      debug: { code: err.code, details: err.details },
    });
  }
});

// ─── POST /api/auth/upload-proof ─────────────────────────────────────────────
const PROOF_ALLOWED_MIME = new Set([
  'image/jpeg', 'image/jpg', 'image/png', 'application/pdf',
]);

const _proofUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (_, file, cb) => {
    if (!PROOF_ALLOWED_MIME.has(file.mimetype)) {
      return cb(new Error('Only JPG, PNG or PDF files are allowed'));
    }
    cb(null, true);
  },
});

function parseProofUpload(field) {
  const middleware = _proofUpload.single(field);
  return (req, res, next) => {
    middleware(req, res, (err) => {
      if (!err) return next();
      return res.status(400).json({ error: err.message });
    });
  };
}

router.post(
  '/upload-proof',
  auth,
  parseProofUpload('file'),
  async (req, res, next) => {
    try {
      if (!req.file) return res.status(400).json({ error: 'No file received' });

      const MAX_SIZE = 5 * 1024 * 1024; // 5 MB
      if (req.file.size > MAX_SIZE) {
        return res.status(400).json({ success: false, error: 'File too large. Maximum 5MB allowed.' });
      }
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
      if (!allowedTypes.includes(req.file.mimetype)) {
        return res.status(400).json({ success: false, error: 'Invalid file type. JPG, PNG or PDF only.' });
      }

      const ext = req.file.mimetype === 'application/pdf' ? 'pdf'
        : req.file.mimetype.split('/')[1].replace('jpeg', 'jpg');
      const storagePath = `proofs/${req.user.id}/${Date.now()}-proof.${ext}`;

      const { error: uploadError } = await supabaseAdmin.storage
        .from('verification-proofs')
        .upload(storagePath, req.file.buffer, {
          contentType: req.file.mimetype,
          upsert: false,
        });
      if (uploadError) throw uploadError;

      // Build a signed URL (private bucket — 1 year expiry for admin review)
      const { data: signedData, error: signedError } = await supabaseAdmin.storage
        .from('verification-proofs')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
      if (signedError) throw signedError;

      const proofUrl = signedData.signedUrl;

      // Update user row
      await supabaseAdmin
        .from('users')
        .update({
          verification_proof_url: proofUrl,
          status: 'proof_submitted',
          proof_submitted_at: new Date().toISOString(),
        })
        .eq('id', req.user.id);

      // Fetch user details for admin notification
      const { data: user } = await supabaseAdmin
        .from('users')
        .select('full_name, email, role, college_name, year_of_study, specialty')
        .eq('id', req.user.id)
        .single();

      // Notify admin
      await sendProofSubmittedNotification(
        process.env.ADMIN_EMAIL || 'aryandevagarwal89000@gmail.com',
        { ...user, proofUrl }
      ).catch(e => console.error('[resend] admin notify failed:', e.message));

      res.json({ ok: true, proofUrl });
    } catch (err) {
      next(err);
    }
  }
);

// ─── POST /api/auth/allied-health-waitlist ────────────────────────────────────
router.post('/allied-health-waitlist', async (req, res, next) => {
  try {
    const { email, profession } = req.body;
    if (!email || !profession) {
      return res.status(400).json({ error: 'email and profession required' });
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email address' });
    }

    const { error } = await supabaseAdmin
      .from('allied_health_waitlist')
      .insert({ email: email.toLowerCase(), profession });
    if (error && error.code !== '23505') throw error; // ignore duplicate

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/auth/register-doctor (legacy — kept for backward compat) ────────
router.post('/register-doctor', async (req, res, next) => {
  try {
    const { email, fullName, mrn, specialty, hospital, yearsExperience, idPhotoUrl } = req.body;
    if (!email || !fullName || !mrn || !specialty) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const lower = email.toLowerCase();
    const { data: existing } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', lower)
      .maybeSingle();
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const slug   = fullName.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
    const handle = `dr-${slug}-${Math.floor(100 + Math.random() * 900)}`;

    // Insert directly into public.users — no Supabase Auth
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        email: lower,
        full_name: fullName,
        role: 'doctor',
        status: 'pending_verification',
        is_verified: false,
        mrn,
        specialty,
        hospital: hospital || null,
        years_experience: yearsExperience ? parseInt(yearsExperience) : null,
        id_photo_url: idPhotoUrl || null,
        handle,
      })
      .select('id')
      .single();

    if (insertError) throw insertError;

    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/auth/complete-profile ─────────────────────────────────────────
router.post('/complete-profile', auth, async (req, res, next) => {
  try {
    const { academicYear, city, state, bio } = req.body;
    await supabaseAdmin
      .from('users')
      .update({ academic_year: academicYear, city, state, bio })
      .eq('id', req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────
router.get('/me', auth, async (req, res, next) => {
  try {
    const { data: user, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', req.user.id)
      .single();
    if (error) throw error;
    res.json({ user });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/auth/pro-status ─────────────────────────────────────────────────
router.get('/pro-status', auth, async (req, res, next) => {
  try {
    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('is_pro, pro_expires_at')
      .eq('id', req.user.id)
      .single();

    const isPro        = !!profile?.is_pro;
    const expiresAt    = profile?.pro_expires_at ? new Date(profile.pro_expires_at) : null;
    const now          = new Date();
    const isExpired    = expiresAt ? expiresAt <= now : true;
    const daysRemaining = expiresAt && !isExpired
      ? Math.ceil((expiresAt - now) / (1000 * 60 * 60 * 24))
      : 0;

    res.json({
      isPro: isPro && !isExpired,
      expiresAt: expiresAt?.toISOString() ?? null,
      daysRemaining,
      isExpired,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
