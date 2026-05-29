const { Resend } = require('resend');

console.log('RESEND KEY CHECK:', process.env.RESEND_API_KEY ? 'LOADED' : 'MISSING');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM   = 'MedGraph <noreply@medgraph.in>';

async function sendOTP(email, otp) {
  console.log('Sending OTP email to:', email);
  console.log('Using Resend key:', process.env.RESEND_API_KEY ? 'SET' : 'NOT SET');
  try {
    const result = await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Your MedGraph verification code',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
          <h1 style="font-size: 24px; color: #1D1D1F;">Your verification code</h1>
          <div style="background: #F5F5F7; border-radius: 16px; padding: 24px; margin: 24px 0; text-align: center;">
            <p style="font-size: 48px; font-weight: 700; letter-spacing: 8px; color: #00C7BE; margin: 0;">${otp}</p>
          </div>
          <p style="color: #6E6E73; font-size: 15px;">This code expires in 10 minutes. If you didn't request this, ignore this email.</p>
          <p style="color: #98989D; font-size: 13px; margin-top: 24px;">MedGraph · Educational platform</p>
        </div>
      `,
    });
    console.log('Resend result:', JSON.stringify(result));
    if (result.error) {
      throw new Error(`Resend API error: ${JSON.stringify(result.error)}`);
    }
    return result;
  } catch (err) {
    console.error('Resend FAILED:', err.message, err);
    throw err;
  }
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
