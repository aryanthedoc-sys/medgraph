const cron = require('node-cron');
const { supabaseAdmin } = require('../services/supabase');
const { sendSessionMatched, sendSessionReminder1h, sendSessionReminder15m, sendNoMatchFound } = require('../services/resend');
const { sendPush } = require('../services/fcm');
const { v4: uuidv4 } = require('uuid');

// ─── Session matching — every 15 minutes ─────────────────────────────────────
cron.schedule('*/15 * * * *', async () => {
  try {
    const { data: pending } = await supabaseAdmin
      .from('session_requests')
      .select('*')
      .eq('status', 'pending');

    if (!pending || pending.length < 2) return;

    const matched = new Set();

    for (let i = 0; i < pending.length; i++) {
      if (matched.has(pending[i].id)) continue;

      for (let j = i + 1; j < pending.length; j++) {
        if (matched.has(pending[j].id)) continue;

        const a = pending[i];
        const b = pending[j];

        if (a.user_id === b.user_id) continue;
        if (a.mode !== b.mode) continue;

        // Date must be same day
        if (a.date !== b.date) continue;

        // Time within ±30 minutes
        const [ah, am] = a.time.split(':').map(Number);
        const [bh, bm] = b.time.split(':').map(Number);
        const diffMins = Math.abs((ah * 60 + am) - (bh * 60 + bm));
        if (diffMins > 30) continue;

        // Topic partial match
        const topicMatch =
          a.topic.toLowerCase().includes(b.topic.toLowerCase()) ||
          b.topic.toLowerCase().includes(a.topic.toLowerCase());
        if (!topicMatch) continue;

        // Create session
        const roomId = `session-${uuidv4()}`;
        const scheduledAt = new Date(`${a.date}T${a.time}:00`).toISOString();
        const { data: session } = await supabaseAdmin
          .from('sessions')
          .insert({
            id: uuidv4(),
            user1_id: a.user_id,
            user2_id: b.user_id,
            room_id: roomId,
            topic: a.topic,
            mode: a.mode,
            status: 'scheduled',
            scheduled_at: scheduledAt,
          })
          .select()
          .single();

        // Update both requests
        await supabaseAdmin
          .from('session_requests')
          .update({ status: 'matched', matched_session_id: session.id })
          .in('id', [a.id, b.id]);

        matched.add(a.id);
        matched.add(b.id);

        // Send emails + push notifications
        const dateTime = `${a.date} at ${a.time}`;
        const [userA, userB] = await Promise.all([
          supabaseAdmin.from('users').select('email, full_name, fcm_token').eq('id', a.user_id).single(),
          supabaseAdmin.from('users').select('email, full_name, fcm_token').eq('id', b.user_id).single(),
        ]);

        await Promise.all([
          sendSessionMatched(userA.data.email, userB.data.full_name, a.topic, dateTime, roomId).catch(console.error),
          sendSessionMatched(userB.data.email, userA.data.full_name, a.topic, dateTime, roomId).catch(console.error),
          sendPush(userA.data.fcm_token, {
            title: 'Session confirmed!',
            body: `Your session with ${userB.data.full_name} on "${a.topic}" is set for ${dateTime}.`,
            data: { type: 'session_matched', sessionId: session.id },
          }),
          sendPush(userB.data.fcm_token, {
            title: 'Session confirmed!',
            body: `Your session with ${userA.data.full_name} on "${a.topic}" is set for ${dateTime}.`,
            data: { type: 'session_matched', sessionId: session.id },
          }),
        ]);
        break;
      }
    }

    // Expire unmatched requests older than 48h
    const cutoff = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const { data: expired } = await supabaseAdmin
      .from('session_requests')
      .update({ status: 'expired' })
      .eq('status', 'pending')
      .lt('created_at', cutoff)
      .select('user_id, topic');

    if (expired) {
      for (const req of expired) {
        const { data: user } = await supabaseAdmin
          .from('users').select('email').eq('id', req.user_id).single();
        if (user) sendNoMatchFound(user.email, req.topic).catch(console.error);
      }
    }
  } catch (err) {
    console.error('[cron:matching]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

// ─── MCQ of the day — 7am IST daily ──────────────────────────────────────────
cron.schedule('0 7 * * *', async () => {
  try {
    const today = new Date().toISOString().substring(0, 10);
    // Check if already posted
    const { data: existing } = await supabaseAdmin
      .from('daily_mcq')
      .select('id')
      .eq('posted_at', today)
      .single();
    if (existing) return;

    // Fetch next unposted MCQ
    const { data: mcq } = await supabaseAdmin
      .from('daily_mcq')
      .select('*')
      .is('posted_at', null)
      .limit(1)
      .single();
    if (!mcq) return;

    await supabaseAdmin
      .from('daily_mcq')
      .update({ posted_at: today })
      .eq('id', mcq.id);

    // Pin as a post in the cases feed (posted by system/admin user)
    // TODO: create a system user in production
    console.log(`[cron:mcq] Posted MCQ for ${today}: ${mcq.question.substring(0, 50)}`);
  } catch (err) {
    console.error('[cron:mcq]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

// ─── Streak notifications — 10pm IST daily ───────────────────────────────────
cron.schedule('0 22 * * *', async () => {
  try {
    const today = new Date().toISOString().substring(0, 10);
    // Find users who haven't had a session today
    const { data: inactive } = await supabaseAdmin
      .from('users')
      .select('id, full_name, current_streak, fcm_token')
      .neq('last_session_date', today)
      .in('status', ['verified_student', 'verified_practitioner'])
      .gt('current_streak', 0);

    if (inactive && inactive.length > 0) {
      console.log(`[cron:streaks] ${inactive.length} users at risk of losing streak`);
      for (const user of inactive) {
        const body = user.current_streak === 1
          ? 'Start a study session today to kick off your streak!'
          : `You're on a ${user.current_streak}-day streak — one session keeps it alive!`;
        sendPush(user.fcm_token, {
          title: "Don't break your streak!",
          body,
          data: { type: 'streak_reminder', streak: String(user.current_streak) },
        }).catch(console.error);
      }
    }
  } catch (err) {
    console.error('[cron:streaks]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

// ─── Weekly rankings — every Monday 8am IST ──────────────────────────────────
cron.schedule('0 8 * * 1', async () => {
  try {
    const weekStart = new Date().toISOString().substring(0, 10);
    const { data: doctors } = await supabaseAdmin
      .from('users')
      .select('id, specialty, follower_count, post_count, current_streak')
      .eq('role', 'doctor')
      .eq('status', 'verified_practitioner');

    if (!doctors) return;

    // Group by specialty, calculate score, rank
    const bySpecialty = {};
    for (const d of doctors) {
      if (!d.specialty) continue;
      if (!bySpecialty[d.specialty]) bySpecialty[d.specialty] = [];
      bySpecialty[d.specialty].push({
        ...d,
        score: d.follower_count * 3 + d.post_count * 2,
      });
    }

    const rows = [];
    for (const [specialty, list] of Object.entries(bySpecialty)) {
      list.sort((a, b) => b.score - a.score);
      list.slice(0, 5).forEach((doc, i) => {
        rows.push({
          id: uuidv4(),
          doctor_id: doc.id,
          specialty,
          rank: i + 1,
          score: doc.score,
          week_start: weekStart,
        });
      });
    }

    if (rows.length > 0) {
      await supabaseAdmin.from('weekly_rankings').insert(rows);
    }

    console.log(`[cron:rankings] Generated ${rows.length} weekly ranking entries`);
  } catch (err) {
    console.error('[cron:rankings]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

// ─── Fame tier update — daily 2am IST ────────────────────────────────────────
cron.schedule('0 2 * * *', async () => {
  try {
    // Update fame tiers based on follower counts
    const tiers = [
      { min: 10000, tier: 'medgraph_fellow' },
      { min: 2000,  tier: 'top_educator' },
      { min: 500,   tier: 'notable' },
      { min: 100,   tier: 'rising' },
      { min: 0,     tier: 'none' },
    ];

    for (const { min, tier } of tiers) {
      const query = supabaseAdmin
        .from('users')
        .update({ fame_tier: tier })
        .eq('role', 'doctor')
        .gte('follower_count', min);

      // For all but the last, also set upper bound
      const nextTier = tiers[tiers.indexOf(tiers.find(t => t.tier === tier)) + 1];
      if (nextTier) {
        query.lt('follower_count', tiers[tiers.indexOf(tiers.find(t => t.tier === tier)) - 1]?.min ?? Infinity);
      }
      await query;
    }
  } catch (err) {
    console.error('[cron:fame]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

// ─── Session reminders — every 15 minutes ────────────────────────────────────
cron.schedule('*/15 * * * *', async () => {
  try {
    const now = new Date();
    const in1hFrom = new Date(now.getTime() + 55 * 60 * 1000).toISOString();
    const in1hTo   = new Date(now.getTime() + 65 * 60 * 1000).toISOString();
    const in15mFrom = new Date(now.getTime() + 10 * 60 * 1000).toISOString();
    const in15mTo   = new Date(now.getTime() + 20 * 60 * 1000).toISOString();

    // 1-hour reminders
    const { data: sessions1h } = await supabaseAdmin
      .from('sessions')
      .select('id, user1_id, user2_id, room_id, topic')
      .eq('status', 'scheduled')
      .eq('reminder_1h_sent', false)
      .gte('scheduled_at', in1hFrom)
      .lte('scheduled_at', in1hTo);

    for (const s of (sessions1h || [])) {
      const [u1, u2] = await Promise.all([
        supabaseAdmin.from('users').select('email, full_name').eq('id', s.user1_id).single(),
        supabaseAdmin.from('users').select('email, full_name').eq('id', s.user2_id).single(),
      ]);
      await Promise.all([
        sendSessionReminder1h(u1.data.email, u2.data.full_name, s.topic, s.room_id).catch(console.error),
        sendSessionReminder1h(u2.data.email, u1.data.full_name, s.topic, s.room_id).catch(console.error),
      ]);
      await supabaseAdmin.from('sessions').update({ reminder_1h_sent: true }).eq('id', s.id);
    }

    // 15-minute reminders
    const { data: sessions15m } = await supabaseAdmin
      .from('sessions')
      .select('id, user1_id, user2_id, room_id, topic')
      .eq('status', 'scheduled')
      .eq('reminder_15m_sent', false)
      .gte('scheduled_at', in15mFrom)
      .lte('scheduled_at', in15mTo);

    for (const s of (sessions15m || [])) {
      const [u1, u2] = await Promise.all([
        supabaseAdmin.from('users').select('email, full_name').eq('id', s.user1_id).single(),
        supabaseAdmin.from('users').select('email, full_name').eq('id', s.user2_id).single(),
      ]);
      await Promise.all([
        sendSessionReminder15m(u1.data.email, u2.data.full_name, s.topic, s.room_id).catch(console.error),
        sendSessionReminder15m(u2.data.email, u1.data.full_name, s.topic, s.room_id).catch(console.error),
      ]);
      await supabaseAdmin.from('sessions').update({ reminder_15m_sent: true }).eq('id', s.id);
    }

    if ((sessions1h?.length || 0) + (sessions15m?.length || 0) > 0) {
      console.log(`[cron:reminders] 1h: ${sessions1h?.length || 0}, 15m: ${sessions15m?.length || 0}`);
    }
  } catch (err) {
    console.error('[cron:reminders]', err.message);
  }
}, { timezone: 'Asia/Kolkata' });

console.log('Cron jobs registered.');
