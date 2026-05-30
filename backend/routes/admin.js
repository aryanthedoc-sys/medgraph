const express = require('express');
const router  = express.Router();
const { supabaseAdmin } = require('../services/supabase');
const {
  sendVerificationApproved,
  sendVerificationRejected,
  sendAccountSuspended,
} = require('../services/resend');

// Admin identified by password — kept simple for internal tooling
function requireAdmin(req, res, next) {
  const pwd = req.headers['x-admin-password'] || req.query.password;
  if (!pwd || pwd !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

// ─── GET /api/admin/pending-verifications ────────────────────────────────────
router.get('/pending-verifications', requireAdmin, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, role, college_name, year_of_study, specialty, verification_proof_url, created_at, report_count')
      .eq('status', 'proof_submitted')
      .order('created_at', { ascending: true });
    if (error) throw error;
    res.json({ users: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/verify-user ─────────────────────────────────────────────
router.post('/verify-user', requireAdmin, async (req, res, next) => {
  try {
    const { userId } = req.body;
    const { data: user } = await supabaseAdmin
      .from('users')
      .select('email, full_name')
      .eq('id', userId)
      .single();

    await supabaseAdmin
      .from('users')
      .update({
        is_verified: true,
        status: 'verified',
        verified_at: new Date().toISOString(),
        verified_by: 'admin',
      })
      .eq('id', userId);

    if (user) {
      await sendVerificationApproved(user.email, user.full_name).catch(console.error);
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/reject-user ─────────────────────────────────────────────
router.post('/reject-user', requireAdmin, async (req, res, next) => {
  try {
    const { userId, reason } = req.body;
    const { data: user } = await supabaseAdmin
      .from('users')
      .select('email, full_name')
      .eq('id', userId)
      .single();

    await supabaseAdmin
      .from('users')
      .update({ status: 'rejected' })
      .eq('id', userId);

    if (user) {
      await sendVerificationRejected(
        user.email,
        user.full_name,
        reason || 'Documents could not be verified.'
      ).catch(console.error);
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/suspend-user ─────────────────────────────────────────────
router.post('/suspend-user', requireAdmin, async (req, res, next) => {
  try {
    const { userId, reason } = req.body;
    const { data: user } = await supabaseAdmin
      .from('users')
      .select('email, full_name')
      .eq('id', userId)
      .single();

    await supabaseAdmin
      .from('users')
      .update({ is_suspended: true, status: 'suspended' })
      .eq('id', userId);

    if (user) {
      await sendAccountSuspended(user.email, user.full_name, reason).catch(console.error);
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/unsuspend-user ──────────────────────────────────────────
router.post('/unsuspend-user', requireAdmin, async (req, res, next) => {
  try {
    const { userId } = req.body;
    await supabaseAdmin
      .from('users')
      .update({ is_suspended: false, status: 'verified' })
      .eq('id', userId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/flagged-users ─────────────────────────────────────────────
router.get('/flagged-users', requireAdmin, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, role, college_name, verification_proof_url, report_count, status, is_suspended')
      .gte('report_count', 3)
      .order('report_count', { ascending: false });
    if (error) throw error;

    // Fetch report reasons for flagged users
    const userIds = (data || []).map(u => u.id);
    let reports = [];
    if (userIds.length > 0) {
      const { data: rData } = await supabaseAdmin
        .from('reports')
        .select('reported_id, reason, created_at')
        .in('reported_id', userIds)
        .order('created_at', { ascending: false });
      reports = rData || [];
    }

    const reportsByUser = {};
    for (const r of reports) {
      if (!reportsByUser[r.reported_id]) reportsByUser[r.reported_id] = [];
      reportsByUser[r.reported_id].push(r.reason);
    }

    const result = (data || []).map(u => ({
      ...u,
      report_reasons: reportsByUser[u.id] || [],
    }));

    res.json({ users: result });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/all-users ─────────────────────────────────────────────────
router.get('/all-users', requireAdmin, async (req, res, next) => {
  try {
    const { page = 1, limit = 50, status, role } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let query = supabaseAdmin
      .from('users')
      .select('id, full_name, email, role, status, is_verified, is_suspended, report_count, vouch_count, created_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    if (status) query = query.eq('status', status);
    if (role)   query = query.eq('role', role);

    const { data, error, count } = await query;
    if (error) throw error;
    res.json({ users: data, total: count });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/pending-doctors (legacy compat) ──────────────────────────
router.get('/pending-doctors', requireAdmin, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, mrn, specialty, id_photo_url, created_at')
      .eq('role', 'doctor')
      .in('status', ['pending_verification', 'proof_submitted'])
      .order('created_at', { ascending: true });
    if (error) throw error;
    res.json({ doctors: data });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/approve/:userId (legacy) ─────────────────────────────────
router.post('/approve/:userId', requireAdmin, async (req, res, next) => {
  try {
    await supabaseAdmin
      .from('users')
      .update({ is_verified: true, status: 'verified', verified_at: new Date().toISOString() })
      .eq('id', req.params.userId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/reject/:userId (legacy) ──────────────────────────────────
router.post('/reject/:userId', requireAdmin, async (req, res, next) => {
  try {
    const { reason } = req.body;
    await supabaseAdmin
      .from('users')
      .update({ status: 'rejected' })
      .eq('id', req.params.userId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/admin/suspend/:userId (legacy) ─────────────────────────────────
router.post('/suspend/:userId', requireAdmin, async (req, res, next) => {
  try {
    await supabaseAdmin
      .from('users')
      .update({ is_suspended: true, status: 'suspended' })
      .eq('id', req.params.userId);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/stats ─────────────────────────────────────────────────────
router.get('/stats', requireAdmin, async (req, res, next) => {
  try {
    const [mbbs, bds, bams, doctors, pending, proSubs, flagged] = await Promise.all([
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'student_mbbs'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'student_bds'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'student_bams'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('role', 'doctor'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('status', 'proof_submitted'),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).eq('is_pro', true),
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }).gte('report_count', 3),
    ]);
    res.json({
      mbbsStudents: mbbs.count,
      bdsStudents: bds.count,
      bamsStudents: bams.count,
      doctors: doctors.count,
      pendingVerification: pending.count,
      activeProSubscribers: proSubs.count,
      flaggedUsers: flagged.count,
    });
  } catch (err) {
    next(err);
  }
});

// ─── GET /api/admin/reports ───────────────────────────────────────────────────
router.get('/reports', requireAdmin, async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('reports')
      .select(`
        *,
        reporter:users!reporter_id (full_name, email),
        reported:users!reported_id (full_name, email, status)
      `)
      .order('created_at', { ascending: false })
      .limit(100);
    if (error) throw error;
    res.json({ reports: data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
