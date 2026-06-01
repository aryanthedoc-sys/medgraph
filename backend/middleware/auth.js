const jwt = require('jsonwebtoken');

/**
 * Verifies the custom JWT signed with JWT_SECRET.
 * Attaches req.user = { id, email, role } on success.
 * The id is the UUID from public.users — no Supabase Auth involved.
 */
async function authMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing auth token' });
    }
    const token = header.slice(7);

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (jwtErr) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    console.log('Auth middleware - decoded id:', decoded.id, 'email:', decoded.email);

    req.user = {
      id:    decoded.id,
      email: decoded.email,
      role:  decoded.role,
    };
    next();
  } catch (err) {
    next(err);
  }
}

/**
 * Same as authMiddleware but allows unauthenticated access.
 * req.user will be null if no token is present.
 */
async function optionalAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header) { req.user = null; return next(); }
  return authMiddleware(req, res, next);
}

module.exports = authMiddleware;
module.exports.optional = optionalAuth;
