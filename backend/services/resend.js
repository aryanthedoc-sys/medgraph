const { Resend } = require('resend');

console.log('RESEND KEY CHECK:', process.env.RESEND_API_KEY ? 'LOADED' : 'MISSING');

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM   = 'MedGraph <noreply@medgraph.in>';
const TEAL   = '#00C7BE';

const _btn = (href, label) =>
  `<a href="${href}" style="display:inline-block;background:#000;color:#fff;font-size:15px;font-weight:600;padding:14px 28px;border-radius:980px;text-decoration:none;margin-top:20px">${label}</a>`;

// ─── OTP ─────────────────────────────────────────────────────────────────────
async function sendOTP(email, otp) {
  console.log('Sending OTP email to:', email);
  try {
    const result = await resend.emails.send({
      from: FROM,
      to: email,
      subject: 'Your MedGraph verification code',
      html: `
        <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
          <h1 style="font-size:24px;color:#1D1D1F">Your verification code</h1>
          <div style="background:#F5F5F7;border-radius:16px;padding:24px;margin:24px 0;text-align:center">
            <p style="font-size:48px;font-weight:700;letter-spacing:8px;color:${TEAL};margin:0">${otp}</p>
          </div>
          <p style="color:#6E6E73;font-size:15px">This code expires in 15 minutes. If you didn't request this, ignore this email.</p>
          <p style="color:#98989D;font-size:13px;margin-top:24px">MedGraph · Educational platform</p>
        </div>
      `,
    });
    console.log('Resend result:', JSON.stringify(result));
    if (result.error) throw new Error(`Resend API error: ${JSON.stringify(result.error)}`);
    return result;
  } catch (err) {
    console.error('Resend FAILED:', err.message, err);
    throw err;
  }
}

// ─── Verification approved ────────────────────────────────────────────────────
async function sendVerificationApproved(email, name) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: '✅ You are now verified on MedGraph',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:22px;font-weight:800;margin:0 0 12px">Welcome, ${name}! ✅</h2>
        <p style="color:#444;margin:0 0 20px">Your credentials have been verified by our medical team. Your verified badge is now live on your profile.</p>
        ${_btn('https://medgraph.in/home', 'Open MedGraph →')}
        <p style="color:#98989D;font-size:13px;margin-top:28px">MedGraph · Educational platform</p>
      </div>
    `,
  });
}

// ─── Verification rejected ────────────────────────────────────────────────────
async function sendVerificationRejected(email, name, reason) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'MedGraph verification update',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:22px;font-weight:800;margin:0 0 12px">Verification update</h2>
        <p style="color:#444;margin:0 0 12px">Hi ${name}, we reviewed your verification request and could not verify your credentials at this time.</p>
        <p style="color:#444;margin:0 0 20px"><strong>Reason:</strong> ${reason}</p>
        <p style="color:#444;margin:0 0 20px">You can upload new documentation from your profile settings to resubmit.</p>
        ${_btn('https://medgraph.in/home', 'Resubmit proof →')}
        <p style="color:#98989D;font-size:13px;margin-top:28px">MedGraph · Educational platform</p>
      </div>
    `,
  });
}

// ─── Account suspended ────────────────────────────────────────────────────────
async function sendAccountSuspended(email, name, reason) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'Your MedGraph account has been suspended',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
        <p style="color:#FF3B30;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:22px;font-weight:800;margin:0 0 12px">Account suspended</h2>
        <p style="color:#444;margin:0 0 12px">Hi ${name}, your account has been suspended.</p>
        ${reason ? `<p style="color:#444;margin:0 0 20px"><strong>Reason:</strong> ${reason}</p>` : ''}
        <p style="color:#444;margin:0 0 20px">If you believe this is a mistake, reply to this email or contact support@medgraph.in.</p>
        <p style="color:#98989D;font-size:13px;margin-top:28px">MedGraph · Educational platform</p>
      </div>
    `,
  });
}

// ─── Admin: proof submitted ───────────────────────────────────────────────────
async function sendProofSubmittedNotification(adminEmail, user) {
  const roleLabel = {
    student_mbbs: 'MBBS Student',
    student_bds: 'BDS Student',
    student_bams: 'BAMS Student',
    doctor: 'Doctor',
  }[user.role] || user.role;

  return resend.emails.send({
    from: FROM,
    to: adminEmail,
    subject: 'New verification proof submitted',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH ADMIN</p>
        <h2 style="font-size:20px;font-weight:800;margin:0 0 16px">New verification proof submitted</h2>
        <table style="width:100%;border-collapse:collapse;font-size:14px">
          <tr><td style="padding:6px 0;color:#888;width:130px">Name</td><td style="padding:6px 0">${user.full_name}</td></tr>
          <tr><td style="padding:6px 0;color:#888">Email</td><td style="padding:6px 0">${user.email}</td></tr>
          <tr><td style="padding:6px 0;color:#888">Type</td><td style="padding:6px 0">${roleLabel}</td></tr>
          ${user.college_name ? `<tr><td style="padding:6px 0;color:#888">College</td><td style="padding:6px 0">${user.college_name}</td></tr>` : ''}
          ${user.year_of_study ? `<tr><td style="padding:6px 0;color:#888">Year</td><td style="padding:6px 0">${user.year_of_study}</td></tr>` : ''}
          ${user.specialty ? `<tr><td style="padding:6px 0;color:#888">Specialty</td><td style="padding:6px 0">${user.specialty}</td></tr>` : ''}
        </table>
        ${_btn(user.proofUrl, 'View proof document →')}
        ${_btn('https://api.medgraph.in/admin', 'Open admin panel →')}
        <p style="color:#98989D;font-size:12px;margin-top:24px">MedGraph · Admin notification</p>
      </div>
    `,
  });
}

// ─── Admin: auto-suspended (5 reports) ───────────────────────────────────────
async function sendAutoSuspendedAlert(adminEmail, user) {
  return resend.emails.send({
    from: FROM,
    to: adminEmail,
    subject: '🚨 User auto-suspended — 5 reports',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px">
        <p style="color:#FF3B30;font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH ADMIN</p>
        <h2 style="font-size:20px;font-weight:800;margin:0 0 16px">🚨 User auto-suspended</h2>
        <p style="color:#444;margin:0 0 16px">A user has been automatically suspended after reaching 5 reports.</p>
        <table style="width:100%;border-collapse:collapse;font-size:14px">
          <tr><td style="padding:6px 0;color:#888;width:130px">Name</td><td style="padding:6px 0">${user.full_name}</td></tr>
          <tr><td style="padding:6px 0;color:#888">Email</td><td style="padding:6px 0">${user.email}</td></tr>
          <tr><td style="padding:6px 0;color:#888">Reports</td><td style="padding:6px 0">${user.report_count}</td></tr>
        </table>
        ${_btn('https://api.medgraph.in/admin', 'Review in admin panel →')}
        <p style="color:#98989D;font-size:12px;margin-top:24px">MedGraph · Admin notification</p>
      </div>
    `,
  });
}

// ─── Welcome Doctor (legacy) ──────────────────────────────────────────────────
async function sendWelcomeDoctor(email, name) {
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: 'Welcome to MedGraph — you\'re verified!',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
        <h2>Welcome, Dr. ${name}</h2>
        <p>Your profile has been verified. You can now log in and start connecting with students.</p>
        ${_btn('https://medgraph.in', 'Open MedGraph')}
      </div>
    `,
  });
}

// ─── Session emails ───────────────────────────────────────────────────────────
async function sendSessionMatched(email, partnerName, topic, dateTime, roomId) {
  const joinLink = `https://medgraph.in/call/${roomId}`;
  return resend.emails.send({
    from: FROM,
    to: email,
    subject: '✅ Study session confirmed!',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;background:#0d0d0d;color:#fff;padding:32px;border-radius:16px">
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
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
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">Starting in 1 hour ⏰</h2>
        <p style="color:#aaa;margin:0 0 24px">Your <strong style="color:#fff">${topic}</strong> session with <strong style="color:#fff">${partnerName}</strong> begins in 60 minutes.</p>
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
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
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
        <p style="color:${TEAL};font-size:12px;font-weight:700;letter-spacing:1.2px;margin:0 0 12px">MEDGRAPH</p>
        <h2 style="font-size:24px;font-weight:800;margin:0 0 8px">No match found</h2>
        <p style="color:#aaa;margin:0 0 24px">We couldn't find a match for your <strong style="color:#fff">${topic}</strong> session. Try booking at a different time.</p>
        ${_btn('https://medgraph.in/sessions', 'Book again →')}
      </div>
    `,
  });
}

module.exports = {
  sendOTP,
  sendVerificationApproved,
  sendVerificationRejected,
  sendAccountSuspended,
  sendProofSubmittedNotification,
  sendAutoSuspendedAlert,
  sendWelcomeDoctor,
  sendSessionMatched,
  sendSessionReminder1h,
  sendSessionReminder15m,
  sendNoMatchFound,
};
