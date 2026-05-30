const express  = require('express');
const router   = express.Router();
const crypto   = require('crypto');
const multer   = require('multer');
const { v4: uuidv4 } = require('uuid');
const { createClient } = require('@supabase/supabase-js');
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
    const lower = email?.toLowerCase();
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
    const rawRole = entry?.userType || bodyRole;
    const safeRole = roleMap[rawRole] || 'student_mbbs';
    const safeName = ((entry?.name || bodyName || '').trim()) || 'User';

    // Create Supabase Auth user with a temporary password
    const tempPassword = uuidv4();
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: lower,
      password: tempPassword,
      email_confirm: true,
    });
    if (authError) throw authError;

    // Build user row
    const userRow = {
      id: authData.user.id,
      email: lower,
      full_name: safeName,
      role: safeRole,
      status: 'pending_verification',
      is_verified: false,
    };

    // Student-specific fields
    if (safeRole !== 'doctor') {
      if (entry?.collegeName)  userRow.college_name  = entry.collegeName;
      if (entry?.collegeCity)  userRow.college_city  = entry.collegeCity;
      if (entry?.collegeState) userRow.college_state = entry.collegeState;
      if (entry?.university)   userRow.university    = entry.university;
      if (entry?.yearOfStudy)  userRow.year_of_study = String(entry.yearOfStudy || '');
    }

    // Doctor-specific fields
    if (safeRole === 'doctor') {
      if (entry?.specialty)       userRow.specialty         = entry.specialty;
      if (entry?.nmcNumber)       userRow.mrn               = entry.nmcNumber;
      if (entry?.yearsExperience) userRow.years_experience  = parseInt(entry.yearsExperience) || null;
    }

    // Insert profile row
    const { data: profileData, error: insertError } = await supabaseAdmin
      .from('users')
      .insert(userRow)
      .select()
      .single();

    if (insertError) {
      console.error('Supabase insert error:', JSON.stringify(insertError));
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw insertError;
    }
    console.log('Profile created:', profileData?.id);

    // Sign in server-side to return a real JWT
    const anonClient = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
    const { data: signInData, error: signInError } = await anonClient.auth.signInWithPassword({
      email: lower,
      password: tempPassword,
    });
    if (signInError) {
      console.error('Server-side sign-in failed:', signInError.message);
      return res.json({ ok: true, isNewUser: true, tempPassword });
    }

    res.json({
      ok: true,
      isNewUser: true,
      userId:       authData.user.id,
      accessToken:  signInData.session.access_token,
      refreshToken: signInData.session.refresh_token,
    });
  } catch (err) {
    console.error('=== USER CREATE ERROR ===');
    console.error('code:', err.code);
    console.error('message:', err.message);
    console.error('details:', err.details);
    console.error('hint:', err.hint);
    console.error('full:', JSON.stringify(err));
    return res.status(500).json({
      success: false,
      error: 'Database error creating new user',
      debug: {
        code: err.code,
        message: err.message,
        details: err.details,
        hint: err.hint,
      },
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
      .single();
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const slug   = fullName.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
    const handle = `dr-${slug}-${Math.floor(100 + Math.random() * 900)}`;
    const tempPassword = uuidv4();
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: lower,
      password: tempPassword,
      email_confirm: true,
    });
    if (authError) throw authError;

    const { error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        id: authData.user.id,
        email: lower,
        full_name: fullName,
        role: 'doctor',
        status: 'pending_verification',
        is_verified: false,
      })
      .select()
      .single();

    if (insertError) {
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw insertError;
    }

    await supabaseAdmin
      .from('users')
      .update({ mrn, specialty, hospital, years_experience: yearsExperience, id_photo_url: idPhotoUrl, handle })
      .eq('id', authData.user.id);

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

module.exports = router;
