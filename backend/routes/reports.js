const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const {
  sendAccountSuspended,
  sendAutoSuspendedAlert,
} = require('../services/resend');
const auth = require('../middleware/auth');

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'aryandevagarwal89000@gmail.com';
const VALID_REASONS = new Set([
  'fake_credentials', 'wrong_qualification', 'impersonating', 'other',
]);

// ─── POST /api/users/:id/report ───────────────────────────────────────────────
router.post('/:id/report', auth, async (req, res, next) => {
  try {
    const reportedId = req.params.id;
    const reporterId = req.user.id;
    const { reason } = req.body;

    if (reportedId === reporterId) {
      return res.status(400).json({ error: 'Cannot report yourself' });
    }
    if (!reason || !VALID_REASONS.has(reason)) {
      return res.status(400).json({ error: 'Invalid reason' });
    }

    // Check: user can only report once per profile
    const { data: existing } = await supabaseAdmin
      .from('reports')
      .select('id')
      .eq('reporter_id', reporterId)
      .eq('reported_id', reportedId)
      .single();
    if (existing) {
      return res.status(409).json({ error: 'You have already reported this user' });
    }

    // Insert report
    await supabaseAdmin.from('reports').insert({
      id: uuidv4(),
      reporter_id: reporterId,
      reported_id: reportedId,
      reason,
    });

    // Increment report_count and check for auto-suspension
    const { data: reported, error: fetchErr } = await supabaseAdmin
      .from('users')
      .select('id, full_name, email, report_count, is_suspended')
      .eq('id', reportedId)
      .single();
    if (fetchErr) throw fetchErr;

    const newCount = (reported.report_count || 0) + 1;
    const updates = { report_count: newCount };

    if (newCount >= 5 && !reported.is_suspended) {
      updates.is_suspended = true;
      updates.status = 'suspended';

      // Email the suspended user
      await sendAccountSuspended(
        reported.email,
        reported.full_name,
        'Your account has been automatically suspended due to multiple reports.'
      ).catch(e => console.error('[resend] suspend email failed:', e.message));

      // Alert admin
      await sendAutoSuspendedAlert(ADMIN_EMAIL, {
        ...reported,
        report_count: newCount,
      }).catch(e => console.error('[resend] admin alert failed:', e.message));
    }

    await supabaseAdmin
      .from('users')
      .update(updates)
      .eq('id', reportedId);

    res.json({ ok: true, message: 'Report submitted' });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/users/:id/vouch ────────────────────────────────────────────────
router.post('/:id/vouch', auth, async (req, res, next) => {
  try {
    const vouchedId = req.params.id;
    const voucherId = req.user.id;

    if (vouchedId === voucherId) {
      return res.status(400).json({ error: 'Cannot vouch for yourself' });
    }

    // Only verified users can vouch
    const { data: voucher } = await supabaseAdmin
      .from('users')
      .select('is_verified')
      .eq('id', voucherId)
      .single();
    if (!voucher?.is_verified) {
      return res.status(403).json({ error: 'Only verified users can vouch' });
    }

    // Insert vouch (unique constraint prevents duplicates)
    const { error: insertErr } = await supabaseAdmin
      .from('vouches')
      .insert({ voucher_id: voucherId, vouched_id: vouchedId });

    if (insertErr) {
      if (insertErr.code === '23505') {
        return res.status(409).json({ error: 'You have already vouched for this user' });
      }
      throw insertErr;
    }

    // Increment vouch_count
    const { data: updated } = await supabaseAdmin
      .from('users')
      .select('vouch_count')
      .eq('id', vouchedId)
      .single();

    const newCount = (updated?.vouch_count || 0) + 1;
    await supabaseAdmin
      .from('users')
      .update({ vouch_count: newCount })
      .eq('id', vouchedId);

    res.json({ ok: true, vouch_count: newCount });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
