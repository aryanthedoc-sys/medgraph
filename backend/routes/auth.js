const express = require('express');
const router  = express.Router();
const crypto  = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const { sendOTP, sendWelcomeDoctor } = require('../services/resend');
const auth = require('../middleware/auth');

console.log('RESEND KEY CHECK:', process.env.RESEND_API_KEY ? 'LOADED' : 'MISSING');

// Temporary OTP store: email → { otp, expiresAt, name, role }
const otpStore = new Map();

// ─── POST /api/auth/send-otp ─────────────────────────────────────────────────
router.post('/send-otp', async (req, res, next) => {
  try {
    const { email, name, role } = req.body;
    if (!email || !name) return res.status(400).json({ error: 'email and name required' });

    // Validate college email for students
    if (role === 'student') {
      const lower = email.toLowerCase();
      const valid = lower.endsWith('.ac.in') || lower.endsWith('.edu') ||
                    lower.includes('.edu.');
      if (!valid) return res.status(400).json({ error: 'Must use a college email (.ac.in or .edu)' });
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
      role,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 min
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
    const { email, otp } = req.body;
    const lower = email?.toLowerCase();
    const entry = otpStore.get(lower);

    if (!entry || entry.otp !== otp || Date.now() > entry.expiresAt) {
      return res.status(400).json({ error: 'Invalid or expired code' });
    }
    otpStore.delete(lower);

    // Create Supabase Auth user with a temporary password
    const tempPassword = uuidv4();
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: lower,
      password: tempPassword,
      email_confirm: true,
    });
    if (authError) throw authError;

    // Insert minimal profile row into public.users
    const { data: profileData, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        id: authData.user.id,
        email: lower,
        full_name: entry.name,
        role: entry.role,
        status: entry.role === 'student' ? 'verified_student' : 'pending_verification',
      })
      .select()
      .single();
    if (insertError) {
      console.error('Supabase insert error:', JSON.stringify(insertError));
      console.error('Error code:', insertError.code);
      console.error('Error message:', insertError.message);
      console.error('Error details:', insertError.details);
      // Clean up the auth user so the email isn't permanently stuck
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw insertError;
    }
    console.log('Profile created:', profileData?.id);

    res.json({ ok: true, isNewUser: true, tempPassword });
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

// ─── POST /api/auth/register-doctor ──────────────────────────────────────────
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

    // Insert minimal profile row into public.users
    const { error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        id: authData.user.id,
        email: lower,
        full_name: fullName,
        role: 'doctor',
        status: 'pending_verification',
      })
      .select()
      .single();
    if (insertError) {
      console.error('Supabase insert error (doctor):', JSON.stringify(insertError));
      console.error('Error code:', insertError.code);
      console.error('Error message:', insertError.message);
      console.error('Error details:', insertError.details);
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw insertError;
    }

    // Update with doctor-specific fields now that the row exists
    const { error: updateError } = await supabaseAdmin
      .from('users')
      .update({ mrn, specialty, hospital, years_experience: yearsExperience, id_photo_url: idPhotoUrl, handle })
      .eq('id', authData.user.id);
    if (updateError) {
      console.error('Supabase update error (doctor fields):', JSON.stringify(updateError));
    }

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
