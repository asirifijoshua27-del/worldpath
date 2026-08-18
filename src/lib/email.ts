import { Resend } from "resend";

// Sends the email-verification link via Resend when RESEND_API_KEY is set.
// Without it (e.g. local development), the link is logged to the server
// console instead, so registration is always testable even with zero
// email setup.

function logToConsole(to: string, name: string, verifyUrl: string) {
  console.log("\n================ WorldPath Group: verification email ================");
  console.log(`To: ${to}`);
  console.log(`Hi ${name}, verify your email and set your password here:`);
  console.log(verifyUrl);
  console.log("=======================================================================\n");
}

function emailHtml(name: string, verifyUrl: string): string {
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    <h1 style="font-size:22px;margin:0 0 16px;">Verify your email</h1>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">Hi ${name},</p>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">
      Thanks for registering with WorldPath Group. Click the button below to verify your
      email address and set your password.
    </p>
    <p style="margin:28px 0;">
      <a href="${verifyUrl}"
         style="background:#0f6e8c;color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:999px;font-size:15px;display:inline-block;">
        Verify email &amp; set password
      </a>
    </p>
    <p style="font-size:13px;line-height:1.6;color:#0a2e3d99;">
      Or copy and paste this link into your browser:<br />
      <span style="word-break:break-all;">${verifyUrl}</span>
    </p>
    <p style="font-size:13px;color:#0a2e3d66;margin-top:32px;">
      If you didn't create an account with WorldPath Group, you can safely ignore this email.
    </p>
  </div>`;
}

function emailText(name: string, verifyUrl: string): string {
  return `Hi ${name},\n\nThanks for registering with WorldPath Group. Verify your email and set your password here:\n${verifyUrl}\n\nIf you didn't create an account with WorldPath Group, you can safely ignore this email.`;
}

export async function sendVerificationEmail(to: string, name: string, verifyUrl: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";

  if (!apiKey) {
    logToConsole(to, name, verifyUrl);
    return;
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: "Verify your WorldPath Group account",
      html: emailHtml(name, verifyUrl),
      text: emailText(name, verifyUrl),
    });
    if (error) {
      console.error("Resend failed to send verification email:", error);
      logToConsole(to, name, verifyUrl); // don't leave the student stuck
    }
  } catch (err) {
    console.error("Error sending verification email via Resend:", err);
    logToConsole(to, name, verifyUrl);
  }
}

export class EmailSendError extends Error {}

function adminEmailHtml(body: string): string {
  const paragraphs = body
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => `<p style="font-size:15px;line-height:1.6;color:#0a2e3d;margin:0 0 14px;">${line}</p>`)
    .join("");
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    ${paragraphs}
  </div>`;
}

/**
 * General-purpose email sender used by the admin portal to message a
 * student directly. Throws EmailSendError if RESEND_API_KEY isn't
 * configured or the send fails, so the caller can show the admin a real
 * error rather than silently pretending it worked.
 */
export async function sendAdminEmail(
  to: string,
  subject: string,
  body: string,
  attachment?: { filename: string; content: Buffer } | null,
  replyTo?: string
) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";

  if (!apiKey) {
    throw new EmailSendError(
      "Email sending isn't configured yet (no RESEND_API_KEY set). This message wasn't sent."
    );
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject,
      html: adminEmailHtml(body),
      text: body,
      attachments: attachment ? [{ filename: attachment.filename, content: attachment.content }] : undefined,
      replyTo: replyTo || undefined,
    });
    if (error) {
      throw new EmailSendError(error.message || "Resend rejected this email.");
    }
  } catch (err) {
    if (err instanceof EmailSendError) throw err;
    throw new EmailSendError("Could not send email. Please try again.");
  }
}


function welcomeEmailHtml(name: string, portalUrl: string): string {
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    <h1 style="font-size:22px;margin:0 0 16px;">Welcome, ${name}!</h1>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">
      Your WorldPath Group account is ready. From your student portal you can track your
      application status, upload documents, and message your counselor directly.
    </p>
    <p style="margin:28px 0;">
      <a href="${portalUrl}"
         style="background:#0f6e8c;color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:999px;font-size:15px;display:inline-block;">
        Go to my portal
      </a>
    </p>
    <p style="font-size:14px;line-height:1.6;color:#0a2e3dcc;">
      A quick tip: check your portal regularly. That's where you'll see updates on your
      application, requests from your counselor, and any documents you still need to submit.
    </p>
    <p style="font-size:13px;color:#0a2e3d66;margin-top:32px;">
      Questions? Just reply to this email or reach us at hello@worldpathgroup.org.
    </p>
  </div>`;
}

function welcomeEmailText(name: string, portalUrl: string): string {
  return `Welcome, ${name}!\n\nYour WorldPath Group account is ready. From your student portal you can track your application status, upload documents, and message your counselor directly.\n\nGo to your portal: ${portalUrl}\n\nTip: check your portal regularly for updates and requests from your counselor.\n\nQuestions? Reach us at hello@worldpathgroup.org.`;
}

/**
 * Sends the welcome email once a student finishes registration (verifies
 * their email and sets a password). Best-effort: failures are logged but
 * never thrown, so a Resend hiccup can't block the student from finishing
 * account setup.
 */
export async function sendWelcomeEmail(to: string, name: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";
  const appUrl = process.env.APP_URL || "http://localhost:3000";
  const portalUrl = `${appUrl}/student`;

  if (!apiKey) {
    console.log(`(Resend not configured) Would send welcome email to ${to}`);
    return;
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: "Welcome to WorldPath Group",
      html: welcomeEmailHtml(name, portalUrl),
      text: welcomeEmailText(name, portalUrl),
    });
    if (error) {
      console.error("Resend failed to send welcome email:", error);
    }
  } catch (err) {
    console.error("Error sending welcome email via Resend:", err);
  }
}

function notificationEmailHtml(title: string, body: string, linkUrl: string): string {
  const paragraph = body
    ? `<p style="font-size:15px;line-height:1.6;color:#0a2e3d;margin:0 0 20px;">${body}</p>`
    : "";
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    <h1 style="font-size:19px;margin:0 0 14px;">${title}</h1>
    ${paragraph}
    <p style="margin:24px 0 0;">
      <a href="${linkUrl}"
         style="background:#0f6e8c;color:#ffffff;text-decoration:none;padding:11px 26px;border-radius:999px;font-size:14px;display:inline-block;">
        View in portal
      </a>
    </p>
  </div>`;
}

function notificationEmailText(title: string, body: string, linkUrl: string): string {
  return `${title}\n\n${body ? body + "\n\n" : ""}View in portal: ${linkUrl}`;
}

/**
 * Sends an email copy of an in-app notification, so people don't have to
 * be actively watching the portal to know something happened. Best-effort:
 * never throws, so a Resend hiccup can't block the notification itself
 * (which is always created in the database regardless of email success).
 */
export async function sendNotificationEmail(to: string, title: string, body: string, linkUrl: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";

  if (!apiKey) {
    console.log(`(Resend not configured) Would send notification email to ${to}: ${title}`);
    return;
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: title,
      html: notificationEmailHtml(title, body, linkUrl),
      text: notificationEmailText(title, body, linkUrl),
    });
    if (error) {
      console.error("Resend failed to send notification email:", error);
    }
  } catch (err) {
    console.error("Error sending notification email via Resend:", err);
  }
}
