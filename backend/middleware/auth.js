const jwt = require('jsonwebtoken');
const { supabaseAdmin } = require('../services/supabase');

/**
 * Verifies the Bearer JWT from Supabase Auth.
 * Attaches req.user = { id, email, role, status, isPro } on success.
 */
async function authMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing auth token' });
    }
    const token = header.slice(7);

    // Verify via Supabase (handles expiry, revocation)
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    // Fetch profile row for role + status
    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('role, status, is_pro, pro_expires_at')
      .eq('id', user.id)
      .single();

    req.user = {
      id:     user.id,
      email:  user.email,
      role:   profile?.role   ?? 'student',
      status: profile?.status ?? 'pending_verification',
      isPro:  profile?.is_pro && new Date(profile.pro_expires_at) > new Date(),
    };
    next();
  } catch (err) {
    next(err);
  }
}

/**
 * Same as authMiddleware but only blocks if token is present and invalid.
 * Allows unauthenticated access (req.user will be null).
 */
async function optionalAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header) { req.user = null; return next(); }
  return authMiddleware(req, res, next);
}

module.exports = authMiddleware;
module.exports.optional = optionalAuth;
