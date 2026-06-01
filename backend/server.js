require('dotenv').config();
const express    = require('express');
const http       = require('http');
const cors       = require('cors');
const helmet     = require('helmet');
const { Server } = require('socket.io');
const path       = require('path');

const rateLimiter  = require('./middleware/rateLimiter');
const authMiddleware = require('./middleware/auth');
const { initSocket } = require('./services/matching');

const authRoutes     = require('./routes/auth');
const postsRoutes    = require('./routes/posts');
const profilesRoutes = require('./routes/profiles');
const paymentsRoutes = require('./routes/payments');
const adminRoutes    = require('./routes/admin');
const searchRoutes   = require('./routes/search');
const sessionsRoutes = require('./routes/sessions');
const roomsRoutes    = require('./routes/rooms');
const leaderboardRoutes = require('./routes/leaderboard');
const uploadsRoutes        = require('./routes/uploads');
const notificationsRoutes  = require('./routes/notifications');
const reportsRoutes        = require('./routes/reports');
const messagesRoutes       = require('./routes/messages');

require('./cron/jobs'); // register all cron jobs

const app    = express();
app.set('trust proxy', 1);
const server = http.createServer(app);

// ─── CORS ────────────────────────────────────────────────────────────────────
const corsOptions = {
  origin: [
    'https://medgraph.in',
    'https://www.medgraph.in',
    'https://medgraph-six.vercel.app',
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:8181',
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ─── Socket.io ───────────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: {
    origin: corsOptions.origin,
    methods: ['GET', 'POST'],
    credentials: true,
  },
  transports: ['websocket', 'polling'],
});

// Track online users for direct message delivery
global.onlineUsers = new Map();
global.io = io;

initSocket(io);

// Online presence tracking for messaging
io.on('connection', (socket) => {
  socket.on('user_online', (userId) => {
    if (userId) {
      global.onlineUsers.set(userId, socket.id);
      console.log('[presence] User online:', userId);
    }
  });

  socket.on('disconnect', () => {
    for (const [uid, sid] of global.onlineUsers) {
      if (sid === socket.id) {
        global.onlineUsers.delete(uid);
        break;
      }
    }
  });
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false })); // CSP off for admin panel
app.use(express.json({ limit: '10mb' }));
app.use(rateLimiter);

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (_, res) => res.json({ status: 'ok', ts: new Date() }));

// ─── Admin panel (static HTML) ────────────────────────────────────────────────
app.use('/admin', express.static(path.join(__dirname, 'admin')));

// ─── API routes ───────────────────────────────────────────────────────────────
app.use('/api/auth',        authRoutes);
app.use('/api/posts',       postsRoutes);
app.use('/api/profiles',    profilesRoutes);
app.use('/api/payments',    paymentsRoutes);
app.use('/api/admin',       adminRoutes);
app.use('/api/search',      searchRoutes);
app.use('/api/sessions',    sessionsRoutes);
app.use('/api/rooms',       roomsRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/uploads',        uploadsRoutes);
app.use('/api/notifications',  notificationsRoutes);
app.use('/api/users',          reportsRoutes);
app.use('/api/messages',       messagesRoutes);

// ─── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, _next) => {
  const status = err.status || 500;
  const message = err.message || 'Internal server error';
  if (process.env.NODE_ENV !== 'production') console.error(err);
  res.status(status).json({ error: message });
});

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || process.env.NODE_PORT || 3000;
server.listen(PORT, () => {
  console.log(`MedGraph backend listening on :${PORT}`);
});
