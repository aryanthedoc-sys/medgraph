const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM   = process.env.RESEND_FROM || 'noreply@medgraph.in';

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

async function sendSessionMatched(email, partnerName, topic, dateTime) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: `Session matched — ${topic}`,
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2>You've been matched!</h2>
        <p>Your session on <strong>${topic}</strong> with <strong>${partnerName}</strong> is confirmed for ${dateTime}.</p>
        <a href="https://medgraph.in/sessions" style="background:#000;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;margin-top:16px">View session</a>
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
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2>No match found</h2>
        <p>We couldn't find a match for your <strong>${topic}</strong> session. Try booking at a different time.</p>
        <a href="https://medgraph.in/sessions" style="background:#000;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;margin-top:16px">Book again</a>
      </div>
    `,
  });
}

module.exports = { sendOTP, sendWelcomeDoctor, sendSessionMatched, sendNoMatchFound };
