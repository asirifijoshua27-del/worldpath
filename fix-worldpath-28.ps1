# WorldPath Group - broadcast/individual admin emails now set a real
# reply-to address (your Contact email from Admin -> Site content),
# instead of the no-reply address. Replies now go somewhere real.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import bcrypt from "bcryptjs";
import { getSession } from "@/lib/auth";
import { saveUploadedImage, deleteUploadedImage, UploadError } from "@/lib/uploads";
import { sendAdminEmail, EmailSendError } from "@/lib/email";
import {
  updateSiteContent,
  createStaff,
  updateStaff,
  deleteStaff,
  getStaffById,
  createBoardMember,
  updateBoardMember,
  deleteBoardMember,
  getBoardMemberById,
  assignStudentStaff,
  updateStudentStatus,
  createUser,
  getUserByEmail,
  getUserByUsername,
  getStudentById,
  getUserById,
  countAdmins,
  deleteUserAccount,
  listStudentsByTrack,
  listStudents,
  createNotification,
  getSiteContent,
} from "@/lib/repo";
import { notifyUser } from "@/lib/notify";
import {
  siteContentSchema,
  staffSchema,
  boardMemberSchema,
  createStaffUserSchema,
  adminEmailSchema,
} from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  return session;
}

export async function updateSiteContentAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const existingLogoUrl = String(formData.get("existingLogoUrl") || "");
  const logoFile = formData.get("logo");

  let logoUrl = existingLogoUrl;
  if (logoFile instanceof File && logoFile.size > 0) {
    try {
      logoUrl = await saveUploadedImage(logoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingLogoUrl) await deleteUploadedImage(existingLogoUrl);
  }

  const existingHeroImageUrl = String(formData.get("existingHeroImageUrl") || "");
  const heroFile = formData.get("hero");

  let heroImageUrl = existingHeroImageUrl;
  if (heroFile instanceof File && heroFile.size > 0) {
    try {
      heroImageUrl = await saveUploadedImage(heroFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingHeroImageUrl) await deleteUploadedImage(existingHeroImageUrl);
  }

  const existingFounderPhotoUrl = String(formData.get("existingFounderPhotoUrl") || "");
  const founderPhotoFile = formData.get("founderPhoto");

  let founderPhotoUrl = existingFounderPhotoUrl;
  if (founderPhotoFile instanceof File && founderPhotoFile.size > 0) {
    try {
      founderPhotoUrl = await saveUploadedImage(founderPhotoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingFounderPhotoUrl) await deleteUploadedImage(existingFounderPhotoUrl);
  }

  const existingWorkVisaHeroImageUrl = String(formData.get("existingWorkVisaHeroImageUrl") || "");
  const workVisaHeroFile = formData.get("workVisaHero");

  let workVisaHeroImageUrl = existingWorkVisaHeroImageUrl;
  if (workVisaHeroFile instanceof File && workVisaHeroFile.size > 0) {
    try {
      workVisaHeroImageUrl = await saveUploadedImage(workVisaHeroFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingWorkVisaHeroImageUrl) await deleteUploadedImage(existingWorkVisaHeroImageUrl);
  }

  const parsed = siteContentSchema.safeParse({
    orgName: String(formData.get("orgName") || ""),
    tagline: String(formData.get("tagline") || ""),
    mission: String(formData.get("mission") || ""),
    vision: String(formData.get("vision") || ""),
    contactEmail: String(formData.get("contactEmail") || ""),
    contactPhone: String(formData.get("contactPhone") || ""),
    address: String(formData.get("address") || ""),
    donateInfo: String(formData.get("donateInfo") || ""),
    caretakingInfo: String(formData.get("caretakingInfo") || ""),
    founderName: String(formData.get("founderName") || ""),
    founderTitle: String(formData.get("founderTitle") || ""),
    founderBio: String(formData.get("founderBio") || ""),
    undergradInfo: String(formData.get("undergradInfo") || ""),
    mastersInfo: String(formData.get("mastersInfo") || ""),
    phdInfo: String(formData.get("phdInfo") || ""),
    scholarshipsInfo: String(formData.get("scholarshipsInfo") || ""),
    workVisaInfo: String(formData.get("workVisaInfo") || ""),
    logoUrl,
    heroImageUrl,
    founderPhotoUrl,
    workVisaHeroImageUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  updateSiteContent(parsed.data);
  revalidatePath("/");
  revalidatePath("/about");
  revalidatePath("/foundation");
  revalidatePath("/programs/undergraduate");
  revalidatePath("/programs/masters");
  revalidatePath("/programs/phd");
  revalidatePath("/scholarships");
  revalidatePath("/work-visa");
  revalidatePath("/contact");
  revalidatePath("/impact");
  revalidatePath("/get-involved");
  revalidatePath("/blog");
  revalidatePath("/admin/content");
  return { success: "Site content updated." };
}

export async function saveStaffAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingPhotoUrl = String(formData.get("existingPhotoUrl") || "");
  const photoFile = formData.get("photo");

  let photoUrl = existingPhotoUrl;
  if (photoFile instanceof File && photoFile.size > 0) {
    try {
      photoUrl = await saveUploadedImage(photoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingPhotoUrl) await deleteUploadedImage(existingPhotoUrl);
  }

  const parsed = staffSchema.safeParse({
    name: String(formData.get("name") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    photoUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (id) {
    updateStaff(id, parsed.data);
  } else {
    createStaff(parsed.data);
  }
  revalidatePath("/admin/staff");
  revalidatePath("/about");
  return { success: "Staff profile saved." };
}

export async function deleteStaffAction(id: string) {
  await requireAdmin();
  const staff = getStaffById(id);
  deleteStaff(id);
  await deleteUploadedImage(staff?.photoUrl);
  revalidatePath("/admin/staff");
  revalidatePath("/about");
}

export async function saveBoardMemberAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingPhotoUrl = String(formData.get("existingPhotoUrl") || "");
  const photoFile = formData.get("photo");

  let photoUrl = existingPhotoUrl;
  if (photoFile instanceof File && photoFile.size > 0) {
    try {
      photoUrl = await saveUploadedImage(photoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingPhotoUrl) await deleteUploadedImage(existingPhotoUrl);
  }

  const parsed = boardMemberSchema.safeParse({
    name: String(formData.get("name") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    photoUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (id) {
    updateBoardMember(id, parsed.data);
  } else {
    createBoardMember(parsed.data);
  }
  revalidatePath("/admin/board");
  revalidatePath("/about");
  return { success: "Board member saved." };
}

export async function deleteBoardMemberAction(id: string) {
  await requireAdmin();
  const member = getBoardMemberById(id);
  deleteBoardMember(id);
  await deleteUploadedImage(member?.photoUrl);
  revalidatePath("/admin/board");
  revalidatePath("/about");
}

export async function assignStudentAction(formData: FormData) {
  await requireAdmin();
  const studentId = String(formData.get("studentId") || "");
  const staffId = String(formData.get("staffId") || "");
  assignStudentStaff(studentId, staffId || null);

  if (staffId) {
    const staff = getStaffById(staffId);
    const student = getStudentById(studentId);
    const studentUser = student ? getUserById(student.userId) : undefined;
    if (staff?.userId && studentUser) {
      await notifyUser({
        userId: staff.userId,
        type: "student_assigned",
        title: "New student assigned to you",
        body: studentUser.name,
        link: `/staff/students/${studentId}`,
      });
    }
  }

  revalidatePath("/admin/students");
}

export async function adminUpdateStatusAction(formData: FormData) {
  await requireAdmin();
  const studentId = String(formData.get("studentId") || "");
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);
  revalidatePath("/admin/students");
}

export async function createStaffUserAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = createStaffUserSchema.safeParse({
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    username: String(formData.get("username") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    tempPassword: String(formData.get("tempPassword") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (getUserByEmail(parsed.data.email)) {
    return { error: "A user with this email already exists." };
  }
  if (getUserByUsername(parsed.data.username)) {
    return { error: "That username is taken." };
  }
  const passwordHash = await bcrypt.hash(parsed.data.tempPassword, 10);
  const user = createUser({
    username: parsed.data.username,
    email: parsed.data.email,
    name: parsed.data.name,
    role: "staff",
    passwordHash,
    emailVerified: true,
  });
  createStaff({ userId: user.id, name: parsed.data.name, title: parsed.data.title, bio: parsed.data.bio });
  revalidatePath("/admin/users");
  revalidatePath("/admin/staff");
  return { success: `Staff account created for ${parsed.data.name}. Share the temporary password securely.` };
}

const MAX_ATTACHMENT_BYTES = 8 * 1024 * 1024; // 8MB

async function readEmailAttachment(formData: FormData): Promise<{ filename: string; content: Buffer } | { error: string } | null> {
  const file = formData.get("attachment");
  if (!(file instanceof File) || file.size === 0) return null;
  if (file.size > MAX_ATTACHMENT_BYTES) {
    return { error: "Attachment must be smaller than 8MB." };
  }
  const content = Buffer.from(await file.arrayBuffer());
  return { filename: file.name, content };
}

export async function emailStudentAction(studentId: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const student = getStudentById(studentId);
  if (!student) {
    return { error: "Student not found." };
  }
  const user = getUserById(student.userId);
  if (!user) {
    return { error: "Student's account not found." };
  }

  const parsed = adminEmailSchema.safeParse({
    subject: String(formData.get("subject") || ""),
    body: String(formData.get("body") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachment = await readEmailAttachment(formData);
  if (attachment && "error" in attachment) {
    return { error: attachment.error };
  }

  try {
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment, getSiteContent().contactEmail);
  } catch (e) {
    if (e instanceof EmailSendError) return { error: e.message };
    throw e;
  }

  return { success: `Email sent to ${user.email}.` };
}

export async function emailStaffAction(staffId: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const staff = getStaffById(staffId);
  if (!staff) {
    return { error: "Staff member not found." };
  }
  const user = staff.userId ? getUserById(staff.userId) : undefined;
  if (!user) {
    return { error: "This staff member doesn't have a linked login account yet, so there's no email to send to." };
  }

  const parsed = adminEmailSchema.safeParse({
    subject: String(formData.get("subject") || ""),
    body: String(formData.get("body") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachment = await readEmailAttachment(formData);
  if (attachment && "error" in attachment) {
    return { error: attachment.error };
  }

  try {
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment, getSiteContent().contactEmail);
  } catch (e) {
    if (e instanceof EmailSendError) return { error: e.message };
    throw e;
  }

  return { success: `Email sent to ${user.email}.` };
}

export async function deleteUserAction(userId: string): Promise<void> {
  const session = await requireAdmin();

  if (userId === session.userId) {
    throw new Error("You can't delete your own account while logged in as it.");
  }

  const target = getUserById(userId);
  if (!target) {
    throw new Error("Account not found.");
  }
  if (target.role === "admin" && countAdmins() <= 1) {
    throw new Error("You can't delete the last remaining admin account.");
  }

  const { staffPhotoUrl, studentPhotoUrl, documentUrls } = deleteUserAccount(userId);

  // Clean up any files this account owned, now that the DB rows are gone.
  await deleteUploadedImage(staffPhotoUrl);
  await deleteUploadedImage(studentPhotoUrl);
  for (const url of documentUrls) {
    await deleteUploadedImage(url);
  }

  revalidatePath("/admin/users");
  revalidatePath("/admin/staff");
  revalidatePath("/admin/students");
  revalidatePath("/about");
}


export async function broadcastMessageAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const group = String(formData.get("group") || "all");
  const subject = String(formData.get("subject") || "");
  const body = String(formData.get("body") || "");

  if (!subject.trim() || !body.trim()) {
    return { error: "Add both a subject and a message." };
  }

  const attachment = await readEmailAttachment(formData);
  if (attachment && "error" in attachment) {
    return { error: attachment.error };
  }

  const replyTo = getSiteContent().contactEmail;

  let recipients;
  if (group === "university") {
    recipients = listStudentsByTrack("university");
  } else if (group === "work_visa") {
    recipients = listStudentsByTrack("work_visa");
  } else {
    recipients = listStudents();
  }

  if (recipients.length === 0) {
    return { error: "No one in that group yet - nothing was sent." };
  }

  let sent = 0;
  let emailed = 0;
  for (const student of recipients) {
    const user = getUserById(student.userId);
    if (!user) continue;

    // The in-app notification always gets created, regardless of whether the
    // email send below succeeds - Resend being unconfigured or rate-limited
    // shouldn't mean the recipient hears nothing at all.
    createNotification({
      userId: user.id,
      type: "message",
      title: subject,
      body: body.slice(0, 120),
      link: "/student",
    });
    sent++;

    try {
      await sendAdminEmail(user.email, subject, body, attachment, replyTo);
      emailed++;
    } catch {
      // Email is best-effort here; the notification above already landed.
    }
  }

  return {
    success: `Notified ${sent} of ${recipients.length} recipient${recipients.length === 1 ? "" : "s"} (emailed ${emailed}).`,
  };
}

'@
[System.IO.File]::WriteAllText("src/app/actions/admin.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/lib/email.ts", $content, $Utf8NoBom)

git add -A
git commit -m "Set a real reply-to address on admin/broadcast emails instead of no-reply"
git push

Write-Host 'Done. Files written and pushed.'