const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { supabaseAdmin } = require('../services/supabase');
const {
  createProSubscription,
  createCreatorPlan,
  createCreatorSubscription,
  verifyWebhookSignature,
} = require('../services/razorpay');
const auth = require('../middleware/auth');

// ─── POST /api/payments/create-pro-subscription ──────────────────────────────
router.post('/create-pro-subscription', auth, async (req, res, next) => {
  try {
    const sub = await createProSubscription();
    res.json({
      subscriptionId: sub.id,
      razorpayKeyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/payments/create-creator-subscription ─────────────────────────
router.post('/create-creator-subscription', auth, async (req, res, next) => {
  try {
    const { creatorId } = req.body;
    if (!creatorId) return res.status(400).json({ error: 'creatorId required' });

    const { data: creator } = await supabaseAdmin
      .from('users')
      .select('subscription_price, razorpay_subscription_id')
      .eq('id', creatorId)
      .single();

    if (!creator?.subscription_price) {
      return res.status(400).json({ error: 'Creator has not set a subscription price' });
    }

    const plan = await createCreatorPlan(creatorId, creator.subscription_price);
    const sub  = await createCreatorSubscription(plan.id);

    res.json({
      subscriptionId: sub.id,
      razorpayKeyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (err) {
    next(err);
  }
});

// ─── POST /api/payments/webhook ─── raw body needed for signature check ──────
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res, next) => {
  try {
    const sig = req.headers['x-razorpay-signature'];
    verifyWebhookSignature(req.body, sig);

    const event = JSON.parse(req.body.toString());
    const entity = event.payload?.subscription?.entity || event.payload?.payment?.entity;

    switch (event.event) {
      case 'subscription.activated': {
        const razId = entity.id;
        await activateSubscription(razId);
        break;
      }
      case 'subscription.cancelled':
      case 'subscription.halted': {
        const razId = entity.id;
        await deactivateSubscription(razId, event.event === 'subscription.halted');
        break;
      }
      case 'payment.captured': {
        const { razorpay_payment_id, razorpay_subscription_id, amount } = entity;
        await supabaseAdmin.from('payments').insert({
          id: uuidv4(),
          razorpay_payment_id,
          razorpay_subscription_id,
          amount,
          currency: 'INR',
          status: 'captured',
        });
        break;
      }
      case 'payment.failed': {
        // Notify user — add notification logic here
        break;
      }
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('Webhook error:', err.message);
    res.status(400).json({ error: err.message });
  }
});

async function activateSubscription(razorpaySubId) {
  // Try Pro subscription first
  const { data: user } = await supabaseAdmin
    .from('users')
    .select('id')
    .eq('razorpay_subscription_id', razorpaySubId)
    .single();

  if (user) {
    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + 1);
    await supabaseAdmin
      .from('users')
      .update({ is_pro: true, pro_expires_at: expiresAt.toISOString() })
      .eq('id', user.id);
    return;
  }

  // Try creator subscription
  const { data: creatorSub } = await supabaseAdmin
    .from('creator_subscriptions')
    .select('id')
    .eq('razorpay_subscription_id', razorpaySubId)
    .single();
  if (creatorSub) {
    await supabaseAdmin
      .from('creator_subscriptions')
      .update({ status: 'active' })
      .eq('id', creatorSub.id);
  }
}

async function deactivateSubscription(razorpaySubId, isHalted) {
  await supabaseAdmin
    .from('users')
    .update({ is_pro: false })
    .eq('razorpay_subscription_id', razorpaySubId);

  await supabaseAdmin
    .from('creator_subscriptions')
    .update({ status: isHalted ? 'expired' : 'cancelled' })
    .eq('razorpay_subscription_id', razorpaySubId);
}

module.exports = router;
