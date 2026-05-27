const Razorpay = require('razorpay');
const crypto   = require('crypto');

const rzp = new Razorpay({
  key_id:     process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

const PRO_AMOUNT = 9900; // ₹99 in paise

/**
 * Creates (or fetches) the MedGraph Pro monthly plan.
 * Razorpay plans are reusable — only created once.
 */
async function getOrCreateProPlan() {
  if (process.env.RAZORPAY_PRO_PLAN_ID) {
    return process.env.RAZORPAY_PRO_PLAN_ID;
  }
  const plan = await rzp.plans.create({
    period: 'monthly',
    interval: 1,
    item: {
      name: 'MedGraph Pro',
      amount: PRO_AMOUNT,
      currency: 'INR',
      description: 'MedGraph Pro monthly subscription',
    },
  });
  return plan.id;
}

async function createProSubscription() {
  const planId = await getOrCreateProPlan();
  return rzp.subscriptions.create({
    plan_id: planId,
    total_count: 120, // 10 years max
    quantity: 1,
  });
}

async function createCreatorPlan(doctorId, priceRupees) {
  return rzp.plans.create({
    period: 'monthly',
    interval: 1,
    item: {
      name: `MedGraph Creator — Doctor ${doctorId}`,
      amount: priceRupees * 100,
      currency: 'INR',
    },
  });
}

async function createCreatorSubscription(planId) {
  return rzp.subscriptions.create({
    plan_id: planId,
    total_count: 120,
    quantity: 1,
  });
}

/**
 * Verifies the Razorpay webhook signature.
 * Throws if invalid — caller should return 400.
 */
function verifyWebhookSignature(body, signature) {
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest('hex');
  if (expected !== signature) {
    throw new Error('Invalid Razorpay webhook signature');
  }
}

module.exports = {
  rzp,
  createProSubscription,
  createCreatorPlan,
  createCreatorSubscription,
  verifyWebhookSignature,
};
