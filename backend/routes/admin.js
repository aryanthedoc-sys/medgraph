const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');
const { sendWelcomeDoctor } = require('../services/resend');

function requireAdminPassword(req, res, next) {
  const pwd = req.headers['x-admin-password'] || req.query.password;
  if (pwd !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

// ─── GET /api/admin/pending-doctors ──────────────────────────────────────────
router.get('/pending-doctors', requireAdminPassword, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, mrn, specialty, id_photo_url, created_at')
      .eq('role', 'doctor')
      .eq('status', 'pending_verification')
      .order('created_at', { ascending: true });
    if (error) throw error;
    res.json({ doctors: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/approve/:userId ─────────────────────────────────────────
router.post('/approve/:userId', requireAdminPassword, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { data: user } = await supabaseAdmin
      .from('users')
      .select('email, full_name')
      .eq('id', userId)
      .single();

    await supabaseAdmin
      .from('users')
      .update({ status: 'verified_practitioner' })
      .eq('id', userId);

    if (user) {
      await sendWelcomeDoctor(user.email, user.full_name).catch(console.error);
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/reject/:userId ──────────────────────────────────────────
router.post('/reject/:userId', requireAdminPassword, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { reason } = req.body;
    await supabaseAdmin
      .from('users')
      .update({ status: 'suspended' })
      .eq('id', userId);
    // TODO: send rejection email with reason
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/reports ───────────────────────────────────────────────────
router.get('/reports', requireAdminPassword, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('reports')
      .select(`
        *,
        reporter:users!reporter_id (full_name, email),
        reported:users!reported_user_id (full_name, email, status)
      `)
      .order('created_at', { ascending: false })
      .limit(100);
    if (error) throw error;
    res.json({ reports: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/suspend/:userId ─────────────────────────────────────────
router.post('/suspend/:userId', requireAdminPassword, async (req, res, next) => {
  try {
    await supabaseAdmin
      .from('users')
      .update({ status: 'suspended' })
      .eq('id', req.params.userId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/stats ─────────────────────────────────────────────────────
router.get('/stats', requireAdminPassword, async (req, res, next) => {
  try {
    const [students, doctors, pending, proSubs] = await Promise.all([
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'student'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'doctor'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('status', 'pending_verification'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('is_pro', true),
    ]);
    res.json({
      totalStudents: students.count,
      totalDoctors: doctors.count,
      pendingVerification: pending.count,
      activeProSubscribers: proSubs.count,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
