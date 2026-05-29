const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM   = 'MedGraph <onboarding@resend.dev>';

async function sendOTP(email, otp) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'Your MedGraph verification code',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2 style="font-size:24px;font-weight:700">MedGraph</h2>
        <p>Your verification code is:</p>
        <div style="font-size:40px;font-weight:800;letter-spacing:8px;margin:16px 0">${otp}</div>
        <p style="color:#666;font-size:13px">This code expires in 10 minutes. Never share it with anyone.</p>
      </div>
    `,
  });
}

async function sendWelcomeDoctor(email, name) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'Welcome to MedGraph — you\'re verified!',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2>Welcome, Dr. ${name}</h2>
        <p>Your profile has been verified. You can now log in and start connecting with students.</p>
        <a href="https://medgraph.in" style="background:#000;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;margin-top:16px">Open MedGraph</a>
      </div>
    `,
  });
}

const _btn = (href, label) =>
  `<a href="${href}" style="display:inline-block;background:#000;color:#fff;font-size:15px;font-weight:600;padding:14px 28px;border-radius:980px;text-decoration:none;margin-top:20px">${label}</a>`;

async function sendSessionMatched(email, partnerName, topic, dateTime, roomId) {
  const joinLink = `https://medgraph.in/call/${roomId}`;
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: '✅ Study session confirmed!',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;background:#0d0d0d;color:#fff;padding:32px;border-radius:16px">
        <p style="color:#00C7BE;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">Session confirmed! 🎉</h2>
        <p style="color:#aaa;margin:0 0 24px">Your study session on <strong style="color:#fff">${topic}</strong> with <strong style="color:#fff">${partnerName}</strong> is set for ${dateTime}.</p>
        ${_btn(joinLink, 'Join session →')}
        <p style="color:#555;font-size:12px;margin-top:28px">Or copy link: ${joinLink}</p>
      </div>
    `,
  });
}

async function sendSessionReminder1h(email, partnerName, topic, roomId) {
  const joinLink = `https://medgraph.in/call/${roomId}`;
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: '⏰ Your session starts in 1 hour',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;background:#0d0d0d;color:#fff;padding:32px;border-radius:16px">
        <p style="color:#00C7BE;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">Starting in 1 hour ⏰</h2>
        <p style="color:#aaa;margin:0 0 24px">Your <strong style="color:#fff">${topic}</strong> session with <strong style="color:#fff">${partnerName}</strong> begins in 60 minutes. Get ready!</p>
        ${_btn(joinLink, 'Open session room →')}
      </div>
    `,
  });
}

async function sendSessionReminder15m(email, partnerName, topic, roomId) {
  const joinLink = `https://medgraph.in/call/${roomId}`;
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: '🚀 Starting in 15 minutes!',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;background:#0d0d0d;color:#fff;padding:32px;border-radius:16px">
        <p style="color:#00C7BE;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">Almost time! 🚀</h2>
        <p style="color:#aaa;margin:0 0 24px">Your <strong style="color:#fff">${topic}</strong> session with <strong style="color:#fff">${partnerName}</strong> starts in 15 minutes.</p>
        ${_btn(joinLink, 'Join now →')}
      </div>
    `,
  });
}

async function sendNoMatchFound(email, topic) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'No match found — try a different time',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;background:#0d0d0d;color:#fff;padding:32px;border-radius:16px">
        <p style="color:#00C7BE;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">No match found</h2>
        <p style="color:#aaa;margin:0 0 24px">We couldn't find a match for your <strong style="color:#fff">${topic}</strong> session. Try booking at a different time.</p>
        ${_btn('https://medgraph.in/sessions', 'Book again →')}
      </div>
    `,
  });
}

module.exports = { sendOTP, sendWelcomeDoctor, sendSessionMatched, sendSessionReminder1h, sendSessionReminder15m, sendNoMatchFound };
