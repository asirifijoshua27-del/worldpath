# WorldPath Group - three changes:
# 1. Phone number is now required on all three registration forms
# 2. Work visa applicants have their own admin section, separate from
#    university/scholarship students
# 3. New 'Message a group' admin page to broadcast an email + notification
#    to Students, Work Visa Applicants, or everyone at once
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
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment);
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
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment);
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
      await sendAdminEmail(user.email, subject, body, attachment);
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

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { redirect } from "next/navigation";
import { randomBytes } from "node:crypto";
import bcrypt from "bcryptjs";
import { registerSchema, freeRegisterSchema, workVisaRegisterSchema, loginSchema } from "@/lib/validators";
import {
  createUser,
  getUserByEmail,
  getUserByUsername,
  createStudentForUser,
  createVerificationToken,
  getVerificationToken,
  markEmailVerified,
  setUserPassword,
  getUserById,
  consumeVerificationToken,
} from "@/lib/repo";
import { notifyAllAdmins } from "@/lib/notify";
import { sendVerificationEmail, sendWelcomeEmail } from "@/lib/email";
import { createSessionToken, setSessionCookie, clearSessionCookie } from "@/lib/auth";
import { saveUploadedImage, UploadError } from "@/lib/uploads";

export type FormState = { error?: string; success?: string };

function slugifyUsername(name: string, email: string): string {
  const base = name.trim().toLowerCase().replace(/[^a-z0-9]+/g, ".").replace(/(^\.|\.$)/g, "");
  return base || email.split("@")[0];
}

async function createAccountAndSendVerification(name: string, email: string) {
  let username = slugifyUsername(name, email);
  let suffix = 0;
  while (true) {
    const candidate = suffix === 0 ? username : `${username}${suffix}`;
    if (!getUserByUsername(candidate)) {
      username = candidate;
      break;
    }
    suffix += 1;
  }

  const user = createUser({
    username,
    email,
    name,
    role: "student",
    passwordHash: null,
    emailVerified: false,
  });

  const token = randomBytes(24).toString("hex");
  createVerificationToken(user.id, token);

  const appUrl = process.env.APP_URL || "http://localhost:3000";
  await sendVerificationEmail(user.email, user.name, `${appUrl}/verify?token=${token}`);

  return user;
}

export async function registerAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = {
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    targetLevel: String(formData.get("targetLevel") || "undergrad"),
    targetCountries: formData.getAll("targetCountries").map(String),
    scholarshipInterest: formData.get("scholarshipInterest") === "on",
    currentEducationLevel: String(formData.get("currentEducationLevel") || "other"),
  };

  const parsed = registerSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form and try again." };
  }

  const photoFile = formData.get("photo");
  if (!(photoFile instanceof File) || photoFile.size === 0) {
    return { error: "Please attach a photo of yourself." };
  }
  let photoUrl: string;
  try {
    photoUrl = await saveUploadedImage(photoFile);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (getUserByEmail(parsed.data.email)) {
    return { error: "An account with this email already exists. Try logging in instead." };
  }

  const user = await createAccountAndSendVerification(parsed.data.name, parsed.data.email);

  createStudentForUser({
    userId: user.id,
    targetLevel: parsed.data.targetLevel as "undergrad" | "masters" | "phd",
    targetCountries: parsed.data.targetCountries,
    scholarshipInterest: parsed.data.scholarshipInterest,
    currentEducationLevel: parsed.data.currentEducationLevel,
    applicationType: "standard",
    photoUrl,
    phone: parsed.data.phone,
  });

  await notifyAllAdmins({
    type: "new_student",
    title: "New student registered",
    body: `${user.name} registered for a standard application.`,
    link: "/admin/students",
  });

  redirect(`/register/check-email?email=${encodeURIComponent(user.email)}`);
}

export async function registerFreeAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = {
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    schoolName: String(formData.get("schoolName") || ""),
    targetCountries: formData.getAll("targetCountries").map(String),
  };

  const parsed = freeRegisterSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form and try again." };
  }

  const photoFile = formData.get("photo");
  if (!(photoFile instanceof File) || photoFile.size === 0) {
    return { error: "Please attach a photo of yourself." };
  }
  let photoUrl: string;
  try {
    photoUrl = await saveUploadedImage(photoFile);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (getUserByEmail(parsed.data.email)) {
    return { error: "An account with this email already exists. Try logging in instead." };
  }

  const user = await createAccountAndSendVerification(parsed.data.name, parsed.data.email);

  createStudentForUser({
    userId: user.id,
    targetLevel: "undergrad",
    targetCountries: parsed.data.targetCountries,
    scholarshipInterest: true,
    currentEducationLevel: "shs_current",
    schoolName: parsed.data.schoolName,
    applicationType: "free_shs",
    photoUrl,
    phone: parsed.data.phone,
  });

  await notifyAllAdmins({
    type: "new_student",
    title: "New free application registered",
    body: `${user.name} registered through the Wesley SHS free program.`,
    link: "/admin/students",
  });

  redirect(`/register/check-email?email=${encodeURIComponent(user.email)}`);
}

export async function registerWorkVisaAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = {
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    profession: String(formData.get("profession") || ""),
    currentOccupation: String(formData.get("currentOccupation") || ""),
    yearsExperience: String(formData.get("yearsExperience") || ""),
    hasJobOffer: formData.get("hasJobOffer") === "on",
    targetCountries: formData.getAll("targetCountries").map(String),
  };

  const parsed = workVisaRegisterSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form and try again." };
  }

  const photoFile = formData.get("photo");
  if (!(photoFile instanceof File) || photoFile.size === 0) {
    return { error: "Please attach a photo of yourself." };
  }
  let photoUrl: string;
  try {
    photoUrl = await saveUploadedImage(photoFile);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (getUserByEmail(parsed.data.email)) {
    return { error: "An account with this email already exists. Try logging in instead." };
  }

  const user = await createAccountAndSendVerification(parsed.data.name, parsed.data.email);

  createStudentForUser({
    userId: user.id,
    targetLevel: "undergrad",
    targetCountries: parsed.data.targetCountries,
    scholarshipInterest: false,
    applicationType: "standard",
    applicationTrack: "work_visa",
    profession: parsed.data.profession,
    currentOccupation: parsed.data.currentOccupation,
    yearsExperience: parsed.data.yearsExperience,
    hasJobOffer: parsed.data.hasJobOffer,
    photoUrl,
    phone: parsed.data.phone,
  });

  await notifyAllAdmins({
    type: "new_student",
    title: "New work visa application registered",
    body: `${user.name} registered for work visa support (${parsed.data.profession}).`,
    link: "/admin/students",
  });

  redirect(`/register/check-email?email=${encodeURIComponent(user.email)}`);
}

export async function setPasswordAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const token = String(formData.get("token") || "");
  const password = String(formData.get("password") || "");
  const confirmPassword = String(formData.get("confirmPassword") || "");

  if (password.length < 8) {
    return { error: "Password must be at least 8 characters." };
  }
  if (password !== confirmPassword) {
    return { error: "Passwords do not match." };
  }

  const record = getVerificationToken(token);
  if (!record || record.used || new Date(record.expiresAt) < new Date()) {
    return { error: "This verification link is invalid or has expired. Please register again." };
  }

  const user = getUserById(record.userId);
  if (!user) {
    return { error: "We couldn't find that account." };
  }

  const passwordHash = await bcrypt.hash(password, 10);
  setUserPassword(user.id, passwordHash);
  markEmailVerified(user.id);
  consumeVerificationToken(token);

  // Registration is now complete - send the welcome email. Best-effort:
  // sendWelcomeEmail never throws, so a Resend hiccup can't block signup.
  await sendWelcomeEmail(user.email, user.name);

  const session = await createSessionToken({ userId: user.id, role: "student", name: user.name });
  await setSessionCookie(session);

  redirect("/student");
}

export async function loginAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = { email: String(formData.get("email") || ""), password: String(formData.get("password") || "") };
  const parsed = loginSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check your details." };
  }

  const user = getUserByEmail(parsed.data.email);
  if (!user || !user.passwordHash) {
    return { error: "Incorrect email or password." };
  }

  const valid = await bcrypt.compare(parsed.data.password, user.passwordHash);
  if (!valid) {
    return { error: "Incorrect email or password." };
  }

  const session = await createSessionToken({ userId: user.id, role: user.role, name: user.name });
  await setSessionCookie(session);

  redirect(`/${user.role}`);
}

export async function logoutAction() {
  await clearSessionCookie();
  redirect("/login");
}


'@
[System.IO.File]::WriteAllText("src/app/actions/auth.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin" | Out-Null
$content = @'
import { getSession } from "@/lib/auth";
import { PortalNav } from "@/components/portal-nav";

const LINKS = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/content", label: "Site content" },
  { href: "/admin/staff", label: "Staff" },
  { href: "/admin/board", label: "Board" },
  { href: "/admin/students", label: "Students" },
  { href: "/admin/work-visa-applicants", label: "Work visa applicants" },
  { href: "/admin/jobs", label: "Job listings" },
  { href: "/admin/blog", label: "Blog" },
  { href: "/admin/impact", label: "Impact stories" },
  { href: "/admin/leads", label: "Leads" },
  { href: "/admin/broadcast", label: "Message a group" },
  { href: "/admin/users", label: "Accounts" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <>
      <PortalNav role="admin" name={session?.name || "Admin"} links={LINKS} />
      <main className="flex-1 mx-auto max-w-6xl w-full px-6 py-10">{children}</main>
    </>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/layout.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getStudentById, getUserById, listNotesForStudent, listStaff, listJobApplicationsForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES, CURRENT_EDUCATION_LEVELS } from "@/types";
import type { DocumentItem } from "@/types";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { MessageThread } from "@/components/message-thread";
import { EmailStudentForm } from "./email-student-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";
import { CheckIcon } from "@/components/check-icon";
import { ApplicationsReview } from "@/components/applications-review";

export const dynamic = "force-dynamic";

export default async function AdminStudentDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const student = getStudentById(id);
  if (!student) notFound();

  const user = getUserById(student.userId);
  const staff = listStaff();
  const assignedStaff = staff.find((s) => s.id === student.assignedStaffId);
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const jobApplications = student.applicationTrack === "work_visa" ? listJobApplicationsForStudent(student.id) : [];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const eduLabel =
    student.currentEducationLevel === "shs_current"
      ? "Currently in Senior High School"
      : CURRENT_EDUCATION_LEVELS.find((l) => l.value === student.currentEducationLevel)?.label ||
        student.currentEducationLevel;

  return (
    <div className="max-w-3xl">
      <div className="flex items-start gap-5 mb-8">
        <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            <PhotoLightbox src={student.photoUrl} alt={user?.name || "Student"} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-xl text-ink/40">
              {user?.name?.charAt(0) ?? "?"}
            </div>
          )}
        </div>
        <div>
          <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-2">
            {student.code}
          </p>
          <h1 className="font-display text-3xl mb-1">{user?.name}</h1>
          <p className="text-ink/60">{user?.email}</p>
        </div>
      </div>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <InfoCard label="Application status" value={statusLabel} />
        <InfoCard
          label="Program"
          value={
            student.applicationTrack === "work_visa"
              ? "Work visa support"
              : student.applicationType === "free_shs"
                ? "Free &middot; SHS partnership"
                : "Standard"
          }
        />
        {student.applicationTrack === "work_visa" ? (
          <>
            <InfoCard label="Profession" value={`${student.profession} - ${targetCountries.join(", ")}`} />
            <InfoCard label="Current occupation" value={student.currentOccupation || "Not specified"} />
            <InfoCard label="Experience" value={student.yearsExperience} />
            <InfoCard label="Job offer" value={student.hasJobOffer ? "Yes" : "Not yet"} />
          </>
        ) : (
          <>
            <InfoCard label="Targeting" value={`${student.targetLevel} - ${targetCountries.join(", ")}`} />
            <InfoCard label="Current education" value={`${eduLabel}${student.schoolName ? ` (${student.schoolName})` : ""}`} />
          </>
        )}
        <InfoCard label="Assigned counselor" value={assignedStaff?.name || "Unassigned"} />
        <InfoCard label="Applied" value={new Date(student.createdAt).toLocaleDateString()} />
        <InfoCard label="Phone" value={student.phone || "Not provided"} />
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <ul className="space-y-2">
          {documents.map((doc) => (
            <li key={doc.name} className="flex items-center justify-between border border-line rounded-lg px-3 py-2 text-sm">
              <span className="flex items-center gap-3">
                <span
                  className={`w-4 h-4 rounded border grid place-items-center text-[10px] ${
                    doc.done ? "bg-teal border-teal text-white" : "border-line"
                  }`}
                >
                  {doc.done ? <CheckIcon className="w-3 h-3" /> : null}
                </span>
                {doc.name}
              </span>
              {doc.fileUrl && (
                <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-teal hover:underline">
                  View file
                </a>
              )}
            </li>
          ))}
        </ul>
      </div>

      {student.applicationTrack === "work_visa" && (
        <div className="mb-10">
          <h2 className="font-display text-xl mb-4">Job Applications</h2>
          <ApplicationsReview applications={jobApplications} />
        </div>
      )}

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Message history</h2>
        <div className="border border-line rounded-xl p-5 max-h-80 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="admin"
          />
        </div>
        <p className="text-xs text-ink/40 mt-2">
          This is the in-app conversation between the student and their counselor. To reach the student directly,
          use the email form below.
        </p>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Email this student</h2>
        {user && <EmailStudentForm studentId={student.id} studentEmail={user.email} />}
      </div>

      {user && (
        <div className="mt-12 pt-8 border-t border-line max-w-lg">
          <h2 className="font-display text-xl mb-2 text-red-700">Danger zone</h2>
          <p className="text-sm text-ink/60 mb-4">
            Deletes {user.name}'s login and their application record, including documents and message
            history. This can't be undone.
          </p>
          <DeleteButton
            id={user.id}
            action={deleteUserAction}
            confirmLabel={`Delete ${user.name}'s account? This removes their login and their entire application record. This can't be undone.`}
          />
        </div>
      )}
    </div>
  );
}

function InfoCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="border border-line rounded-xl p-4">
      <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">{label}</p>
      <p className="text-sm capitalize">{value}</p>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/students/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/students" | Out-Null
$content = @'
import { listStudentsByTrack, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "./student-row";

export const dynamic = "force-dynamic";

export default function AdminStudentsPage() {
  const students = listStudentsByTrack("university");
  const staff = listStaff();

  const rows = students.map((s) => {
    const user = getUserById(s.userId);
    return {
      id: s.id,
      userId: s.userId,
      code: s.code,
      name: user?.name || "-",
      email: user?.email || "-",
      targetLevel: s.targetLevel,
      status: s.status,
      assignedStaffId: s.assignedStaffId,
      applicationType: s.applicationType,
      schoolName: s.schoolName,
      photoUrl: s.photoUrl,
      applicationTrack: s.applicationTrack,
      profession: s.profession,
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Students</h1>
      <p className="text-ink/60 mb-8">
        University and scholarship applicants only.{" "}
        <a href="/admin/work-visa-applicants" className="text-teal hover:underline">
          Work visa applicants are managed separately &rarr;
        </a>
      </p>

      <div className="overflow-x-auto border border-line rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
              <th className="py-3 px-4 font-medium"></th>
              <th className="py-3 px-4 font-medium">Code</th>
              <th className="py-3 px-4 font-medium">Student</th>
              <th className="py-3 px-4 font-medium">Program</th>
              <th className="py-3 px-4 font-medium">Level</th>
              <th className="py-3 px-4 font-medium">Status</th>
              <th className="py-3 px-4 font-medium">Assigned staff</th>
              <th className="py-3 px-4 font-medium"></th>
            </tr>
          </thead>
          <tbody className="px-4">
            {rows.length === 0 && (
              <tr>
                <td colSpan={8} className="py-6 px-4 text-ink/50 italic">
                  No students have registered yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <StudentRow key={r.id} student={r} staffOptions={staff.map((s) => ({ id: s.id, name: s.name }))} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/students/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/register/free" | Out-Null
$content = @'
"use client";

import { useActionState, startTransition } from "react";
import Link from "next/link";
import { registerFreeAction, type FormState } from "@/app/actions/auth";
import { TARGET_COUNTRIES } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";

const initialState: FormState = {};

export default function FreeRegisterPage() {
  const [state, formAction, pending] = useActionState(registerFreeAction, initialState);

  // See the comment in /register/page.tsx: submitting manually (instead of
  // wiring `action` directly to the form) keeps the student's answers on
  // screen if a field needs fixing, rather than wiping the whole form.
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => {
      formAction(formData);
    });
  }

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Free application program</p>
        <h1 className="font-display text-3xl mt-3 mb-2">For current Senior High School students</h1>
        <p className="text-sm text-ink/70 mb-8">
          Through our partnership with Wesley Senior High School, current SHS students get full
          undergraduate application support at no cost. You'll get a WorldPath student code and a
          link to verify your email and set a password.
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Ama Serwaa Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Phone number">
            <input name="phone" type="tel" required className="input" placeholder="e.g. 024 000 0000" />
          </Field>

          <Field label="Your school's name">
            <input name="schoolName" required className="input" placeholder="e.g. Wesley Senior High School" />
          </Field>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Apply for free"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Not currently in Senior High School?{" "}
          <Link href="/register" className="text-teal hover:underline">
            Use the standard application
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/register/free/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/register" | Out-Null
$content = @'
"use client";

import { useActionState, useRef, startTransition, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { registerAction, type FormState } from "@/app/actions/auth";
import { TARGET_LEVELS, TARGET_COUNTRIES, CURRENT_EDUCATION_LEVELS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";
import { ArrowRight } from "@/components/arrow-right";

const initialState: FormState = {};

function RegisterForm() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);
  const searchParams = useSearchParams();
  const levelParam = searchParams.get("level");
  const defaultLevel = TARGET_LEVELS.some((l) => l.value === levelParam) ? levelParam! : "undergrad";

  // React resets uncontrolled form fields the moment a <form action={...}>
  // submits - including on a failed submission. On a form this long,
  // that means a student who forgets one field (like the photo) would
  // see everything they typed disappear. Submitting manually like this,
  // instead of wiring `action` directly to the form, keeps their answers
  // on screen if something needs fixing.
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => {
      formAction(formData);
    });
  }

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Get started</p>
        <h1 className="font-display text-3xl mt-3 mb-2">Create your student account</h1>
        <p className="text-sm text-ink/70 mb-6">
          You'll get a WorldPath student code and a link to verify your email and set a password.
        </p>

        <div className="mb-8 rounded-xl border border-gold-deep/30 bg-gold/5 px-4 py-3 text-sm">
          Currently a Senior High School student?{" "}
          <Link href="/register/free" className="text-gold-deep font-medium hover:underline">
            Apply through our free application program
            <ArrowRight />
          </Link>
        </div>

        <form ref={formRef} onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Ama Serwaa Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Phone number">
            <input name="phone" type="tel" required className="input" placeholder="e.g. 024 000 0000" />
          </Field>

          <Field label="What are you applying for?">
            <select name="targetLevel" className="input" defaultValue={defaultLevel}>
              {TARGET_LEVELS.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </Field>

          <Field label="Your current education level">
            <select name="currentEducationLevel" className="input" defaultValue="tertiary">
              {CURRENT_EDUCATION_LEVELS.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </Field>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="scholarshipInterest" defaultChecked className="accent-teal" />
            I'm interested in scholarship / financial aid support
          </label>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Create account"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Already registered?{" "}
          <Link href="/login" className="text-teal hover:underline">
            Log in
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}

export default function RegisterPage() {
  return (
    <Suspense fallback={null}>
      <RegisterForm />
    </Suspense>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/register/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/register/work-visa" | Out-Null
$content = @'
"use client";

import { useActionState, startTransition } from "react";
import Link from "next/link";
import { registerWorkVisaAction, type FormState } from "@/app/actions/auth";
import { TARGET_COUNTRIES, YEARS_EXPERIENCE_OPTIONS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";

const initialState: FormState = {};

export default function WorkVisaRegisterPage() {
  const [state, formAction, pending] = useActionState(registerWorkVisaAction, initialState);

  // See the comment in /register/page.tsx: submitting manually (instead of
  // wiring `action` directly to the form) keeps the applicant's answers on
  // screen if a field needs fixing, rather than wiping the whole form.
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => {
      formAction(formData);
    });
  }

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Work visa support</p>
        <h1 className="font-display text-3xl mt-3 mb-2">Apply for work visa guidance</h1>
        <p className="text-sm text-ink/70 mb-8">
          For any Ghanaian pursuing a work visa abroad, in any profession or destination. You'll get
          a WorldPath applicant code, your own portal, and a counselor to guide your application.
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Kwame Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Phone number">
            <input name="phone" type="tel" required className="input" placeholder="e.g. 024 000 0000" />
          </Field>

          <Field label="Profession / field">
            <input name="profession" required className="input" placeholder="e.g. Nursing, Software Engineering, Hospitality" />
          </Field>

          <Field label="Current occupation (optional)">
            <input name="currentOccupation" className="input" placeholder="e.g. Staff Nurse at Korle Bu" />
          </Field>

          <Field label="Years of experience">
            <select name="yearsExperience" required className="input" defaultValue="">
              <option value="" disabled>
                Select...
              </option>
              {YEARS_EXPERIENCE_OPTIONS.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </Field>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="hasJobOffer" className="accent-teal" />
            I already have a job offer from an employer abroad
          </label>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Apply for work visa support"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Applying for university or a scholarship instead?{" "}
          <Link href="/register" className="text-teal hover:underline">
            Use the standard application
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/register/work-visa/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, getStudentById, getUserById, listNotesForStudent, listJobApplicationsForStudent } from "@/lib/repo";
import { StatusSelect } from "./status-select";
import { DocumentChecklist } from "./document-checklist";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { ApplicationsReview } from "@/components/applications-review";
import { staffAddNoteAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export const dynamic = "force-dynamic";

export default async function StaffStudentPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const session = await getSession();
  const staff = session ? getStaffByUserId(session.userId) : undefined;
  const student = getStudentById(id);

  if (!student || !staff || student.assignedStaffId !== staff.id) notFound();

  const user = getUserById(student.userId);
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const jobApplications = student.applicationTrack === "work_visa" ? listJobApplicationsForStudent(student.id) : [];
  const addNote = staffAddNoteAction.bind(null, student.id);

  return (
    <div className="max-w-3xl">
      <div className="flex items-start gap-5 mb-8">
        <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            <PhotoLightbox src={student.photoUrl} alt={user?.name || "Student"} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-xl text-ink/40">
              {user?.name?.charAt(0) ?? "?"}
            </div>
          )}
        </div>
        <div>
          <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-2">
            {student.code}
          </p>
          <h1 className="font-display text-3xl mb-1">{user?.name}</h1>
          <p className="text-ink/60">{user?.email}</p>
          {student.phone && <p className="text-ink/60">{student.phone}</p>}
        </div>
      </div>

      <div className="grid sm:grid-cols-2 gap-8 mb-10">
        <div>
          <h2 className="text-sm font-medium mb-2">Application status</h2>
          <StatusSelect studentId={student.id} status={student.status} />
        </div>
        <div>
          {student.applicationTrack === "work_visa" ? (
            <>
              <h2 className="text-sm font-medium mb-2">Profession</h2>
              <p className="text-sm text-ink/70">{student.profession}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
              <p className="text-sm text-ink/70 mt-2">
                {student.yearsExperience} experience &middot; {student.hasJobOffer ? "Has a job offer" : "No job offer yet"}
              </p>
            </>
          ) : (
            <>
              <h2 className="text-sm font-medium mb-2">Targeting</h2>
              <p className="text-sm text-ink/70 capitalize">{student.targetLevel}</p>
              <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
            </>
          )}
        </div>
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <DocumentChecklist studentId={student.id} documents={documents} />
      </div>

      {student.applicationTrack === "work_visa" && (
        <div className="mb-10">
          <h2 className="font-display text-xl mb-4">Job Applications</h2>
          <ApplicationsReview applications={jobApplications} />
        </div>
      )}

      <div>
        <h2 className="font-display text-xl mb-4">Messages</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="staff"
          />
        </div>
        <MessageForm action={addNote} placeholder="Send a message to this student..." />
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/staff/students/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import fs from "node:fs";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";

// This project uses Node's built-in `node:sqlite` module as its database
// driver so the app runs with zero native-binary installs. The data model
// mirrors docs/schema.prisma.reference exactly, so migrating to Prisma +
// Postgres later is a mechanical port, not a redesign. See README.md.

const DB_PATH = process.env.DATABASE_FILE || path.join(process.cwd(), "data", "worldpath.db");

function getDb(): DatabaseSync {
  const g = globalThis as unknown as { __worldpathDb?: DatabaseSync };
  if (g.__worldpathDb) return g.__worldpathDb;

  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const db = new DatabaseSync(DB_PATH);
  db.exec("PRAGMA journal_mode = WAL;");
  db.exec("PRAGMA foreign_keys = ON;");
  migrate(db);
  seed(db);
  g.__worldpathDb = db;
  return db;
}

function migrate(db: DatabaseSync) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      passwordHash TEXT,
      role TEXT NOT NULL DEFAULT 'student',
      name TEXT NOT NULL,
      emailVerified INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS staff_profiles (
      id TEXT PRIMARY KEY,
      userId TEXT UNIQUE REFERENCES users(id),
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS board_members (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS students (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE NOT NULL,
      userId TEXT UNIQUE NOT NULL REFERENCES users(id),
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      targetCountries TEXT NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'new',
      assignedStaffId TEXT REFERENCES staff_profiles(id),
      documents TEXT NOT NULL DEFAULT '[]',
      scholarshipInterest INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS student_notes (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      authorId TEXT NOT NULL REFERENCES users(id),
      text TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS site_content (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      orgName TEXT NOT NULL DEFAULT 'WorldPath Group',
      tagline TEXT NOT NULL DEFAULT '',
      mission TEXT NOT NULL DEFAULT '',
      vision TEXT NOT NULL DEFAULT '',
      contactEmail TEXT NOT NULL DEFAULT '',
      contactPhone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS email_verifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT UNIQUE NOT NULL,
      expiresAt TEXT NOT NULL,
      used INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS counters (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      link TEXT,
      read INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      employer TEXT NOT NULL,
      country TEXT NOT NULL,
      city TEXT NOT NULL DEFAULT '',
      industry TEXT NOT NULL DEFAULT '',
      employmentType TEXT NOT NULL DEFAULT '',
      experienceRequired TEXT NOT NULL DEFAULT '',
      educationRequirement TEXT NOT NULL DEFAULT '',
      languageRequirement TEXT NOT NULL DEFAULT '',
      salary TEXT NOT NULL DEFAULT '',
      sponsorshipInfo TEXT NOT NULL DEFAULT '',
      applicationDeadline TEXT,
      lastVerifiedDate TEXT,
      source TEXT NOT NULL DEFAULT '',
      verificationStatus TEXT NOT NULL DEFAULT 'pending_verification',
      applicationUrl TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS job_applications (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      jobId TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
      status TEXT NOT NULL DEFAULT 'saved',
      notes TEXT NOT NULL DEFAULT '',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      UNIQUE(studentId, jobId)
    );

    CREATE TABLE IF NOT EXISTS blog_posts (
      id TEXT PRIMARY KEY,
      slug TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      excerpt TEXT NOT NULL DEFAULT '',
      body TEXT NOT NULL DEFAULT '',
      coverImageUrl TEXT,
      tags TEXT NOT NULL DEFAULT '[]',
      authorName TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      publishedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS impact_stories (
      id TEXT PRIMARY KEY,
      studentName TEXT NOT NULL,
      headline TEXT NOT NULL,
      story TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      destinationCountry TEXT NOT NULL DEFAULT '',
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      featured INTEGER NOT NULL DEFAULT 0,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS volunteer_leads (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL DEFAULT 'volunteer',
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      message TEXT NOT NULL DEFAULT '',
      handled INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  `);

  // Columns added after the initial release go here as best-effort ALTERs
  // (existing databases won't have them; CREATE TABLE IF NOT EXISTS above
  // only helps brand-new installs). Safe to ignore "duplicate column".
  const alters = [
    "ALTER TABLE site_content ADD COLUMN donateInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN logoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN caretakingInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE student_notes ADD COLUMN attachmentUrl TEXT",
    "ALTER TABLE students ADD COLUMN currentEducationLevel TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN schoolName TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationType TEXT NOT NULL DEFAULT 'standard'",
    "ALTER TABLE students ADD COLUMN photoUrl TEXT",
    "ALTER TABLE volunteer_leads ADD COLUMN areasOfInterest TEXT NOT NULL DEFAULT '[]'",
    "ALTER TABLE volunteer_leads ADD COLUMN availability TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN heroImageUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN founderName TEXT NOT NULL DEFAULT 'Cyril Asirifi Kwame'",
    "ALTER TABLE site_content ADD COLUMN founderTitle TEXT NOT NULL DEFAULT 'Founder & Executive Director'",
    "ALTER TABLE site_content ADD COLUMN founderBio TEXT NOT NULL DEFAULT 'Passionate about expanding access to international education and scholarship opportunities for students across Ghana.'",
    "ALTER TABLE site_content ADD COLUMN founderPhotoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN undergradInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN mastersInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN phdInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN scholarshipsInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN workVisaInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN workVisaHeroImageUrl TEXT",
    "ALTER TABLE students ADD COLUMN applicationTrack TEXT NOT NULL DEFAULT 'university'",
    "ALTER TABLE students ADD COLUMN profession TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN currentOccupation TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN yearsExperience TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN hasJobOffer INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE students ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
  ];
  for (const sql of alters) {
    try {
      db.exec(sql);
    } catch {
      // Column already exists ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â fine.
    }
  }
}

function seed(db: DatabaseSync) {
  const now = new Date().toISOString();

  const contentRow = db.prepare("SELECT id FROM site_content WHERE id = 1").get();
  if (!contentRow) {
    db.prepare(
      `INSERT INTO site_content (id, orgName, tagline, mission, vision, contactEmail, contactPhone, address, donateInfo, caretakingInfo)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      "WorldPath Group",
      "Opening the world's classrooms to Ghana's brightest students.",
      "WorldPath Group helps talented undergraduate, master's, and PhD students across Ghana apply to universities abroad and secure the scholarships that make it possible \u2014 with priority access for students whose families cannot otherwise afford it, including orphans.",
      "A future where a student's potential, not their family's income, determines which universities are open to them.",
      "hello@worldpathgroup.org",
      "",
      "Accra, Ghana",
      "Update this from Admin \u2192 Site content with your bank account or mobile money details.",
      "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities \u2014 because a student's wellbeing at home is part of their path to university too."
    );
  }

  const adminRow = db.prepare("SELECT id FROM users WHERE role = 'admin' LIMIT 1").get();
  if (!adminRow) {
    const id = randomUUID();
    const passwordHash = bcrypt.hashSync("ChangeMe123!", 10);
    db.prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, 'admin', ?, 1, ?, ?)`
    ).run(id, "admin", "admin@worldpathgroup.org", passwordHash, "WorldPath Admin", now, now);
  }
}

// node:sqlite returns row objects with a null prototype. That's invisible
// almost everywhere, but React Server Components refuse to serialize
// null-prototype objects when passing data to Client Components ("Only
// plain objects... can be passed"). This thin wrapper spreads every row
// into a genuine plain object so callers never have to think about it.
type SQLInputValue = null | number | bigint | string | NodeJS.ArrayBufferView;

interface PlainStatement {
  get(...params: SQLInputValue[]): Record<string, unknown> | undefined;
  all(...params: SQLInputValue[]): Record<string, unknown>[];
  run(...params: SQLInputValue[]): unknown;
}

interface PlainDb {
  prepare(sql: string): PlainStatement;
}

function wrapDb(raw: DatabaseSync): PlainDb {
  return {
    prepare(sql: string) {
      const stmt = raw.prepare(sql);
      return {
        get: (...params: SQLInputValue[]) => {
          const row = stmt.get(...params);
          return row ? { ...(row as object) } : undefined;
        },
        all: (...params: SQLInputValue[]) => {
          return stmt.all(...params).map((row) => ({ ...(row as object) }));
        },
        run: (...params: SQLInputValue[]) => stmt.run(...params),
      };
    },
  };
}

export function db(): PlainDb {
  return wrapDb(getDb());
}

/**
 * Temporarily disables foreign key enforcement, runs fn, then re-enables it.
 * Used only for account deletion: a deleted staff/admin's authored messages
 * are kept (for the student's record) rather than deleted, which would
 * otherwise violate the foreign key on student_notes.authorId.
 */
export function withForeignKeysOff<T>(fn: () => T): T {
  const raw = getDb();
  raw.exec("PRAGMA foreign_keys = OFF;");
  try {
    return fn();
  } finally {
    raw.exec("PRAGMA foreign_keys = ON;");
  }
}

export function nowIso(): string {
  return new Date().toISOString();
}

export function newId(): string {
  return randomUUID();
}

/** Generates the next sequential student code for the current year, e.g. WPG-2026-0001 */
export function nextStudentCode(): string {
  const year = new Date().getFullYear();
  const counterId = `student-${year}`;
  const database = getDb();
  const existing = database.prepare("SELECT value FROM counters WHERE id = ?").get(counterId) as
    | { value: number }
    | undefined;
  const next = (existing?.value ?? 0) + 1;
  if (existing) {
    database.prepare("UPDATE counters SET value = ? WHERE id = ?").run(next, counterId);
  } else {
    database.prepare("INSERT INTO counters (id, value) VALUES (?, ?)").run(counterId, next);
  }
  return `WPG-${year}-${String(next).padStart(4, "0")}`;
}


'@
[System.IO.File]::WriteAllText("src/lib/db.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { db, newId, nowIso, nextStudentCode, withForeignKeysOff } from "@/lib/db";
import type {
  UserRecord,
  StaffProfileRecord,
  BoardMemberRecord,
  StudentRecord,
  StudentNoteRecord,
  SiteContentRecord,
  BlogPostRecord,
  ImpactStoryRecord,
  VolunteerLeadRecord,
  LeadType,
  Role,
  TargetLevel,
  DocumentItem,
  NotificationRecord,
  NotificationType,
  JobRecord,
  JobVerificationStatus,
  JobApplicationRecord,
  JobApplicationStatus,
} from "@/types";

const DEFAULT_CHECKLIST: DocumentItem[] = [
  { name: "Passport / national ID", done: false },
  { name: "Academic transcripts", done: false },
  { name: "Personal statement / essay", done: false },
  { name: "Recommendation letters", done: false },
  { name: "English proficiency test (if required)", done: false },
  { name: "Financial / sponsorship documents", done: false },
];

const WORK_VISA_CHECKLIST: DocumentItem[] = [
  { name: "Passport", done: false },
  { name: "CV / resume", done: false },
  { name: "Professional qualification / certification", done: false },
  { name: "Reference letters from past employers", done: false },
  { name: "Language proficiency test (if required)", done: false },
  { name: "Job offer letter (if you have one)", done: false },
  { name: "Police clearance certificate", done: false },
  { name: "Medical certificate", done: false },
];

// ---------- Users ----------

export function getUserByEmail(email: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE email = ?").get(email) as UserRecord | undefined;
}

export function getUserByUsername(username: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE username = ?").get(username) as UserRecord | undefined;
}

export function getUserById(id: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE id = ?").get(id) as UserRecord | undefined;
}

export function listUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users ORDER BY createdAt DESC").all() as unknown as UserRecord[];
}

export function countAdmins(): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM users WHERE role = 'admin'").get() as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

/**
 * Deletes a user account and whatever it owns: for staff, their public
 * profile (and unassigns any students); for students, their application
 * record. Messages the account authored are kept for the record ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â see
 * listNotesForStudent ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â rather than deleted.
 */
export function deleteUserAccount(userId: string): { staffPhotoUrl: string | null; studentPhotoUrl: string | null; documentUrls: string[] } {
  const database = db();
  let staffPhotoUrl: string | null = null;
  let studentPhotoUrl: string | null = null;
  let documentUrls: string[] = [];

  withForeignKeysOff(() => {
    const staff = database.prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
      | StaffProfileRecord
      | undefined;
    if (staff) {
      staffPhotoUrl = staff.photoUrl;
      database.prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(staff.id);
      database.prepare("DELETE FROM staff_profiles WHERE id = ?").run(staff.id);
    }

    const student = database.prepare("SELECT * FROM students WHERE userId = ?").get(userId) as
      | StudentRecord
      | undefined;
    if (student) {
      studentPhotoUrl = student.photoUrl;
      documentUrls = (JSON.parse(student.documents) as { fileUrl?: string | null }[])
        .map((d) => d.fileUrl)
        .filter((u): u is string => Boolean(u));
      database.prepare("DELETE FROM students WHERE id = ?").run(student.id);
    }

    database.prepare("DELETE FROM email_verifications WHERE userId = ?").run(userId);
    database.prepare("DELETE FROM users WHERE id = ?").run(userId);
  });

  return { staffPhotoUrl, studentPhotoUrl, documentUrls };
}

export function createUser(input: {
  username: string;
  email: string;
  name: string;
  role: Role;
  passwordHash?: string | null;
  emailVerified?: boolean;
}): UserRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.username,
      input.email,
      input.passwordHash ?? null,
      input.role,
      input.name,
      input.emailVerified ? 1 : 0,
      now,
      now
    );
  return getUserById(id)!;
}

export function setUserPassword(userId: string, passwordHash: string) {
  db()
    .prepare("UPDATE users SET passwordHash = ?, updatedAt = ? WHERE id = ?")
    .run(passwordHash, nowIso(), userId);
}

export function markEmailVerified(userId: string) {
  db().prepare("UPDATE users SET emailVerified = 1, updatedAt = ? WHERE id = ?").run(nowIso(), userId);
}

// ---------- Email verification tokens ----------

export function createVerificationToken(userId: string, token: string, ttlHours = 48) {
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();
  db()
    .prepare(
      `INSERT INTO email_verifications (id, userId, token, expiresAt, used, createdAt)
       VALUES (?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), userId, token, expiresAt, nowIso());
}

export function getVerificationToken(token: string) {
  return db().prepare("SELECT * FROM email_verifications WHERE token = ?").get(token) as
    | { id: string; userId: string; token: string; expiresAt: string; used: number }
    | undefined;
}

export function consumeVerificationToken(token: string) {
  db().prepare("UPDATE email_verifications SET used = 1 WHERE token = ?").run(token);
}

// ---------- Staff profiles ----------

export function listStaff(): StaffProfileRecord[] {
  return db().prepare("SELECT * FROM staff_profiles ORDER BY sortOrder ASC, name ASC").all() as unknown as StaffProfileRecord[];
}

export function getStaffById(id: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE id = ?").get(id) as StaffProfileRecord | undefined;
}

export function getStaffByUserId(userId: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
    | StaffProfileRecord
    | undefined;
}

export function createStaff(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  userId?: string | null;
  sortOrder?: number;
}): StaffProfileRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO staff_profiles (id, userId, name, title, bio, photoUrl, sortOrder)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(id, input.userId ?? null, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getStaffById(id)!;
}

export function updateStaff(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(
      `UPDATE staff_profiles SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`
    )
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteStaff(id: string) {
  db().prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(id);
  db().prepare("DELETE FROM staff_profiles WHERE id = ?").run(id);
}

// ---------- Board members ----------

export function listBoardMembers(): BoardMemberRecord[] {
  return db().prepare("SELECT * FROM board_members ORDER BY sortOrder ASC, name ASC").all() as unknown as BoardMemberRecord[];
}

export function getBoardMemberById(id: string): BoardMemberRecord | undefined {
  return db().prepare("SELECT * FROM board_members WHERE id = ?").get(id) as BoardMemberRecord | undefined;
}

export function createBoardMember(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  sortOrder?: number;
}): BoardMemberRecord {
  const id = newId();
  db()
    .prepare(`INSERT INTO board_members (id, name, title, bio, photoUrl, sortOrder) VALUES (?, ?, ?, ?, ?, ?)`)
    .run(id, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getBoardMemberById(id)!;
}

export function updateBoardMember(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(`UPDATE board_members SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`)
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteBoardMember(id: string) {
  db().prepare("DELETE FROM board_members WHERE id = ?").run(id);
}

// ---------- Students ----------

export function listStudents(): StudentRecord[] {
  return db().prepare("SELECT * FROM students ORDER BY createdAt DESC").all() as unknown as StudentRecord[];
}

export function listStudentsByTrack(track: "university" | "work_visa"): StudentRecord[] {
  return db()
    .prepare("SELECT * FROM students WHERE applicationTrack = ? ORDER BY createdAt DESC")
    .all(track) as unknown as StudentRecord[];
}

export function listStudentsByStaff(staffId: string): StudentRecord[] {
  return db()
    .prepare("SELECT * FROM students WHERE assignedStaffId = ? ORDER BY createdAt DESC")
    .all(staffId) as unknown as StudentRecord[];
}

export function getStudentById(id: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE id = ?").get(id) as StudentRecord | undefined;
}

export function getStudentByUserId(userId: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE userId = ?").get(userId) as StudentRecord | undefined;
}

export function createStudentForUser(input: {
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string[];
  scholarshipInterest: boolean;
  currentEducationLevel?: string;
  schoolName?: string;
  applicationType?: "standard" | "free_shs";
  photoUrl?: string | null;
  applicationTrack?: "university" | "work_visa";
  profession?: string;
  currentOccupation?: string;
  yearsExperience?: string;
  hasJobOffer?: boolean;
  phone?: string;
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  const track = input.applicationTrack ?? "university";
  const checklist = track === "work_visa" ? WORK_VISA_CHECKLIST : DEFAULT_CHECKLIST;
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, photoUrl, applicationTrack, profession, currentOccupation, yearsExperience, hasJobOffer, phone, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      code,
      input.userId,
      input.targetLevel,
      JSON.stringify(input.targetCountries),
      JSON.stringify(checklist),
      input.scholarshipInterest ? 1 : 0,
      input.currentEducationLevel ?? "",
      input.schoolName ?? "",
      input.applicationType ?? "standard",
      input.photoUrl ?? null,
      track,
      input.profession ?? "",
      input.currentOccupation ?? "",
      input.yearsExperience ?? "",
      input.hasJobOffer ? 1 : 0,
      input.phone ?? "",
      now,
      now
    );
  return getStudentById(id)!;
}

export function updateStudentStatus(id: string, status: string) {
  db().prepare("UPDATE students SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function assignStudentStaff(id: string, staffId: string | null) {
  db().prepare("UPDATE students SET assignedStaffId = ?, updatedAt = ? WHERE id = ?").run(staffId, nowIso(), id);
}

export function updateStudentDocuments(id: string, documents: DocumentItem[]) {
  db()
    .prepare("UPDATE students SET documents = ?, updatedAt = ? WHERE id = ?")
    .run(JSON.stringify(documents), nowIso(), id);
}

export function updateStudentTargets(
  id: string,
  input: { targetLevel: TargetLevel; targetCountries: string[]; scholarshipInterest: boolean }
) {
  db()
    .prepare(
      "UPDATE students SET targetLevel = ?, targetCountries = ?, scholarshipInterest = ?, updatedAt = ? WHERE id = ?"
    )
    .run(input.targetLevel, JSON.stringify(input.targetCountries), input.scholarshipInterest ? 1 : 0, nowIso(), id);
}

// ---------- Student notes ----------

export function listNotesForStudent(
  studentId: string
): (StudentNoteRecord & { authorName: string; authorRole: Role })[] {
  return db()
    .prepare(
      `SELECT n.*, COALESCE(u.name, 'Former team member') as authorName, COALESCE(u.role, 'staff') as authorRole
       FROM student_notes n
       LEFT JOIN users u ON u.id = n.authorId
       WHERE n.studentId = ? ORDER BY n.createdAt ASC`
    )
    .all(studentId) as unknown as (StudentNoteRecord & { authorName: string; authorRole: Role })[];
}

export function addNote(studentId: string, authorId: string, text: string, attachmentUrl?: string | null) {
  db()
    .prepare(
      `INSERT INTO student_notes (id, studentId, authorId, text, attachmentUrl, createdAt) VALUES (?, ?, ?, ?, ?, ?)`
    )
    .run(newId(), studentId, authorId, text, attachmentUrl ?? null, nowIso());
}

// ---------- Site content ----------

export function getSiteContent(): SiteContentRecord {
  return db().prepare("SELECT * FROM site_content WHERE id = 1").get() as unknown as SiteContentRecord;
}

export function updateSiteContent(input: Omit<SiteContentRecord, "id">) {
  db()
    .prepare(
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, founderName = ?, founderTitle = ?, founderBio = ?, founderPhotoUrl = ?, undergradInfo = ?, mastersInfo = ?, phdInfo = ?, scholarshipsInfo = ?, workVisaInfo = ?, workVisaHeroImageUrl = ?, caretakingInfo = ?
       WHERE id = 1`
    )
    .run(
      input.orgName,
      input.tagline,
      input.mission,
      input.vision,
      input.contactEmail,
      input.contactPhone,
      input.address,
      input.donateInfo,
      input.logoUrl,
      input.heroImageUrl,
      input.founderName,
      input.founderTitle,
      input.founderBio,
      input.founderPhotoUrl,
      input.undergradInfo,
      input.mastersInfo,
      input.phdInfo,
      input.scholarshipsInfo,
      input.workVisaInfo,
      input.workVisaHeroImageUrl,
      input.caretakingInfo
    );
}

// ---------- Blog posts ----------

function slugify(title: string): string {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .slice(0, 80);
}

export function uniqueSlug(title: string, excludeId?: string): string {
  const base = slugify(title) || "post";
  let slug = base;
  let n = 1;
  while (true) {
    const existing = db().prepare("SELECT id FROM blog_posts WHERE slug = ?").get(slug) as
      | { id: string }
      | undefined;
    if (!existing || existing.id === excludeId) return slug;
    n += 1;
    slug = `${base}-${n}`;
  }
}

export function listPublishedPosts(): BlogPostRecord[] {
  return db()
    .prepare("SELECT * FROM blog_posts WHERE published = 1 ORDER BY publishedAt DESC")
    .all() as unknown as BlogPostRecord[];
}

export function listAllPosts(): BlogPostRecord[] {
  return db().prepare("SELECT * FROM blog_posts ORDER BY createdAt DESC").all() as unknown as BlogPostRecord[];
}

export function getPostBySlug(slug: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE slug = ?").get(slug) as unknown as
    | BlogPostRecord
    | undefined;
}

export function getPostById(id: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE id = ?").get(id) as unknown as BlogPostRecord | undefined;
}

export function createPost(input: {
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl?: string;
  tags: string[];
  authorName: string;
  published: boolean;
}): BlogPostRecord {
  const id = newId();
  const now = nowIso();
  const slug = uniqueSlug(input.title);
  db()
    .prepare(
      `INSERT INTO blog_posts
        (id, slug, title, excerpt, body, coverImageUrl, tags, authorName, published, publishedAt, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      input.published ? now : null,
      now,
      now
    );
  return getPostById(id)!;
}

export function updatePost(
  id: string,
  input: {
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl?: string;
    tags: string[];
    authorName: string;
    published: boolean;
  }
) {
  const existing = getPostById(id);
  if (!existing) return;
  const slug = existing.title === input.title ? existing.slug : uniqueSlug(input.title, id);
  const publishedAt = input.published ? existing.publishedAt || nowIso() : null;
  db()
    .prepare(
      `UPDATE blog_posts SET slug = ?, title = ?, excerpt = ?, body = ?, coverImageUrl = ?, tags = ?, authorName = ?, published = ?, publishedAt = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      publishedAt,
      nowIso(),
      id
    );
}

export function deletePost(id: string) {
  db().prepare("DELETE FROM blog_posts WHERE id = ?").run(id);
}

// ---------- Impact stories ----------

export function listImpactStories(): ImpactStoryRecord[] {
  return db()
    .prepare("SELECT * FROM impact_stories ORDER BY sortOrder ASC, createdAt DESC")
    .all() as unknown as ImpactStoryRecord[];
}

export function getImpactStoryById(id: string): ImpactStoryRecord | undefined {
  return db().prepare("SELECT * FROM impact_stories WHERE id = ?").get(id) as unknown as
    | ImpactStoryRecord
    | undefined;
}

export function createImpactStory(input: {
  studentName: string;
  headline: string;
  story: string;
  photoUrl?: string;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: boolean;
  sortOrder?: number;
}): ImpactStoryRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO impact_stories
        (id, studentName, headline, story, photoUrl, destinationCountry, targetLevel, featured, sortOrder, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      nowIso()
    );
  return getImpactStoryById(id)!;
}

export function updateImpactStory(
  id: string,
  input: {
    studentName: string;
    headline: string;
    story: string;
    photoUrl?: string;
    destinationCountry: string;
    targetLevel: TargetLevel;
    featured: boolean;
    sortOrder?: number;
  }
) {
  db()
    .prepare(
      `UPDATE impact_stories SET studentName = ?, headline = ?, story = ?, photoUrl = ?, destinationCountry = ?, targetLevel = ?, featured = ?, sortOrder = ?
       WHERE id = ?`
    )
    .run(
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      id
    );
}

export function deleteImpactStory(id: string) {
  db().prepare("DELETE FROM impact_stories WHERE id = ?").run(id);
}

// ---------- Volunteer / donate / apply leads ----------

export function listLeads(): VolunteerLeadRecord[] {
  return db().prepare("SELECT * FROM volunteer_leads ORDER BY createdAt DESC").all() as unknown as VolunteerLeadRecord[];
}

export function createLead(input: {
  type: LeadType;
  name: string;
  email: string;
  phone?: string;
  message: string;
  areasOfInterest?: string[];
  availability?: string;
}) {
  db()
    .prepare(
      `INSERT INTO volunteer_leads (id, type, name, email, phone, message, areasOfInterest, availability, handled, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(
      newId(),
      input.type,
      input.name,
      input.email,
      input.phone ?? null,
      input.message,
      JSON.stringify(input.areasOfInterest ?? []),
      input.availability ?? "",
      nowIso()
    );
}

export function markLeadHandled(id: string, handled: boolean) {
  db().prepare("UPDATE volunteer_leads SET handled = ? WHERE id = ?").run(handled ? 1 : 0, id);
}


// ---------- Notifications ----------

export function createNotification(input: {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
}) {
  db()
    .prepare(
      `INSERT INTO notifications (id, userId, type, title, body, link, read, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), input.userId, input.type, input.title, input.body ?? "", input.link ?? null, nowIso());
}

/** Notify every admin at once - used for events any admin should see (new student, new lead). */
export function notifyAllAdmins(input: { type: NotificationType; title: string; body?: string; link?: string }) {
  const admins = db().prepare("SELECT id FROM users WHERE role = 'admin'").all() as unknown as { id: string }[];
  for (const admin of admins) {
    createNotification({ ...input, userId: admin.id });
  }
}

/** Full admin user records (id, email, name) - used to email every admin, not just notify in-app. */
export function listAdminUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users WHERE role = 'admin'").all() as unknown as UserRecord[];
}

export function listNotifications(userId: string, limit = 20): NotificationRecord[] {
  return db()
    .prepare("SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC LIMIT ?")
    .all(userId, limit) as unknown as NotificationRecord[];
}

export function countUnreadNotifications(userId: string): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND read = 0").get(userId) as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

export function markNotificationRead(id: string, userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE id = ? AND userId = ?").run(id, userId);
}

export function markAllNotificationsRead(userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE userId = ? AND read = 0").run(userId);
}

// ---------- Jobs ----------

export function createJob(input: {
  title: string;
  employer: string;
  country: string;
  city?: string;
  industry?: string;
  employmentType?: string;
  experienceRequired?: string;
  educationRequirement?: string;
  languageRequirement?: string;
  salary?: string;
  sponsorshipInfo?: string;
  applicationDeadline?: string | null;
  lastVerifiedDate?: string | null;
  source?: string;
  verificationStatus?: JobVerificationStatus;
  applicationUrl?: string;
  description?: string;
  published?: boolean;
}): JobRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO jobs
        (id, title, employer, country, city, industry, employmentType, experienceRequired, educationRequirement, languageRequirement, salary, sponsorshipInfo, applicationDeadline, lastVerifiedDate, source, verificationStatus, applicationUrl, description, published, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.title,
      input.employer,
      input.country,
      input.city ?? "",
      input.industry ?? "",
      input.employmentType ?? "",
      input.experienceRequired ?? "",
      input.educationRequirement ?? "",
      input.languageRequirement ?? "",
      input.salary ?? "",
      input.sponsorshipInfo ?? "",
      input.applicationDeadline ?? null,
      input.lastVerifiedDate ?? null,
      input.source ?? "",
      input.verificationStatus ?? "pending_verification",
      input.applicationUrl ?? "",
      input.description ?? "",
      input.published ? 1 : 0,
      now,
      now
    );
  return getJobById(id)!;
}

export function updateJob(
  id: string,
  input: Partial<Omit<JobRecord, "id" | "createdAt" | "updatedAt" | "published">> & { published?: boolean | number }
) {
  const current = getJobById(id);
  if (!current) return;
  const merged = {
    ...current,
    ...input,
    published: input.published === undefined ? current.published : input.published ? 1 : 0,
  };
  db()
    .prepare(
      `UPDATE jobs SET title = ?, employer = ?, country = ?, city = ?, industry = ?, employmentType = ?, experienceRequired = ?, educationRequirement = ?, languageRequirement = ?, salary = ?, sponsorshipInfo = ?, applicationDeadline = ?, lastVerifiedDate = ?, source = ?, verificationStatus = ?, applicationUrl = ?, description = ?, published = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      merged.title,
      merged.employer,
      merged.country,
      merged.city,
      merged.industry,
      merged.employmentType,
      merged.experienceRequired,
      merged.educationRequirement,
      merged.languageRequirement,
      merged.salary,
      merged.sponsorshipInfo,
      merged.applicationDeadline,
      merged.lastVerifiedDate,
      merged.source,
      merged.verificationStatus,
      merged.applicationUrl,
      merged.description,
      merged.published ? 1 : 0,
      nowIso(),
      id
    );
}

export function deleteJob(id: string) {
  db().prepare("DELETE FROM jobs WHERE id = ?").run(id);
}

export function getJobById(id: string): JobRecord | undefined {
  return db().prepare("SELECT * FROM jobs WHERE id = ?").get(id) as JobRecord | undefined;
}

/** All jobs, newest first - for the admin list (includes unpublished/expired). */
export function listAllJobs(): JobRecord[] {
  return db().prepare("SELECT * FROM jobs ORDER BY createdAt DESC").all() as unknown as JobRecord[];
}

/** Published, non-expired jobs only - for the public site. */
export function listPublishedJobs(): JobRecord[] {
  return db()
    .prepare("SELECT * FROM jobs WHERE published = 1 AND verificationStatus != 'expired' ORDER BY createdAt DESC")
    .all() as unknown as JobRecord[];
}

// ---------- Job applications ----------

/** Saves a job for a student (status "saved") if not already tracked. Safe to call repeatedly. */
export function saveJobForStudent(studentId: string, jobId: string): JobApplicationRecord {
  const existing = getJobApplication(studentId, jobId);
  if (existing) return existing;
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO job_applications (id, studentId, jobId, status, notes, createdAt, updatedAt)
       VALUES (?, ?, ?, 'saved', '', ?, ?)`
    )
    .run(id, studentId, jobId, now, now);
  return getJobApplicationById(id)!;
}

export function getJobApplication(studentId: string, jobId: string): JobApplicationRecord | undefined {
  return db()
    .prepare("SELECT * FROM job_applications WHERE studentId = ? AND jobId = ?")
    .get(studentId, jobId) as JobApplicationRecord | undefined;
}

export function getJobApplicationById(id: string): JobApplicationRecord | undefined {
  return db().prepare("SELECT * FROM job_applications WHERE id = ?").get(id) as JobApplicationRecord | undefined;
}

export function updateJobApplicationStatus(id: string, status: JobApplicationStatus) {
  db().prepare("UPDATE job_applications SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function withdrawJobApplication(id: string) {
  db().prepare("UPDATE job_applications SET status = 'withdrawn', updatedAt = ? WHERE id = ?").run(nowIso(), id);
}

export function deleteJobApplication(id: string) {
  db().prepare("DELETE FROM job_applications WHERE id = ?").run(id);
}

/** A student's tracked applications, newest first, with the job details joined in. */
export function listJobApplicationsForStudent(studentId: string): (JobApplicationRecord & { job: JobRecord })[] {
  const rows = db()
    .prepare(
      `SELECT ja.*, 
        j.id as job_id, j.title as job_title, j.employer as job_employer, j.country as job_country,
        j.city as job_city, j.industry as job_industry, j.employmentType as job_employmentType,
        j.applicationUrl as job_applicationUrl, j.verificationStatus as job_verificationStatus
       FROM job_applications ja
       JOIN jobs j ON j.id = ja.jobId
       WHERE ja.studentId = ?
       ORDER BY ja.updatedAt DESC`
    )
    .all(studentId) as unknown as Record<string, unknown>[];

  return rows.map((r) => ({
    id: r.id as string,
    studentId: r.studentId as string,
    jobId: r.jobId as string,
    status: r.status as JobApplicationStatus,
    notes: r.notes as string,
    createdAt: r.createdAt as string,
    updatedAt: r.updatedAt as string,
    job: {
      id: r.job_id as string,
      title: r.job_title as string,
      employer: r.job_employer as string,
      country: r.job_country as string,
      city: r.job_city as string,
      industry: r.job_industry as string,
      employmentType: r.job_employmentType as string,
      applicationUrl: r.job_applicationUrl as string,
      verificationStatus: r.job_verificationStatus as JobVerificationStatus,
    } as JobRecord,
  }));
}

export function countJobApplicationsByStatus(studentId: string): Record<string, number> {
  const rows = db()
    .prepare("SELECT status, COUNT(*) as count FROM job_applications WHERE studentId = ? GROUP BY status")
    .all(studentId) as unknown as { status: string; count: number }[];
  const counts: Record<string, number> = {};
  for (const row of rows) counts[row.status] = row.count;
  return counts;
}

'@
[System.IO.File]::WriteAllText("src/lib/repo.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
  scholarshipInterest: z.boolean(),
  currentEducationLevel: z.enum(["shs_graduate", "tertiary", "graduate", "other"]),
});

export const freeRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  schoolName: z.string().min(2, "Enter your school's name"),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
});

export const workVisaRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  profession: z.string().min(2, "Enter your profession or field"),
  currentOccupation: z.string().optional().default(""),
  yearsExperience: z.string().min(1, "Select your years of experience"),
  hasJobOffer: z.boolean(),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination country"),
});

export const setPasswordSchema = z
  .object({
    token: z.string().min(1),
    password: z.string().min(8, "Password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

export const loginSchema = z.object({
  email: z.string().email("Enter a valid email address"),
  password: z.string().min(1, "Enter your password"),
});

export const siteContentSchema = z.object({
  orgName: z.string().min(1),
  tagline: z.string().min(1),
  mission: z.string().min(1),
  vision: z.string().min(1),
  contactEmail: z.string().email(),
  contactPhone: z.string().optional().default(""),
  address: z.string().optional().default(""),
  donateInfo: z.string().optional().default(""),
  logoUrl: z.string().optional().default(""),
  heroImageUrl: z.string().optional().default(""),
  founderName: z.string().optional().default(""),
  founderTitle: z.string().optional().default(""),
  founderBio: z.string().optional().default(""),
  founderPhotoUrl: z.string().optional().default(""),
  undergradInfo: z.string().optional().default(""),
  mastersInfo: z.string().optional().default(""),
  phdInfo: z.string().optional().default(""),
  scholarshipsInfo: z.string().optional().default(""),
  workVisaInfo: z.string().optional().default(""),
  workVisaHeroImageUrl: z.string().optional().default(""),
  caretakingInfo: z.string().optional().default(""),
});

export const staffSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const boardMemberSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const noteSchema = z.object({
  text: z.string().optional().default(""),
});

export const createStaffUserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  username: z.string().min(3),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  tempPassword: z.string().min(8),
});

export const blogPostSchema = z.object({
  title: z.string().min(3, "Title is required"),
  excerpt: z.string().min(1, "Add a short excerpt for search results and previews"),
  body: z.string().min(1, "Post body cannot be empty"),
  coverImageUrl: z.string().optional().default(""),
  tags: z.array(z.string()).default([]),
  authorName: z.string().min(1, "Author name is required"),
  published: z.boolean(),
});

export const impactStorySchema = z.object({
  studentName: z.string().min(1, "Student name is required"),
  headline: z.string().min(1, "Headline is required"),
  story: z.string().min(1, "Story text is required"),
  photoUrl: z.string().optional().default(""),
  destinationCountry: z.string().min(1, "Destination is required"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  featured: z.boolean(),
});

export const leadSchema = z
  .object({
    type: z.enum(["volunteer", "donate", "apply_interest", "contact"]),
    name: z.string().min(2, "Enter your name"),
    email: z.string().email("Enter a valid email address"),
    phone: z.string().optional().default(""),
    message: z.string().optional().default(""),
    areasOfInterest: z.array(z.string()).optional().default([]),
    availability: z.string().optional().default(""),
  })
  .refine((data) => !["donate", "contact"].includes(data.type) || data.message.trim().length > 0, {
    message: "Please add a short message",
    path: ["message"],
  })
  .refine((data) => data.type !== "volunteer" || data.areasOfInterest.length > 0, {
    message: "Choose at least one area you'd like to help with",
    path: ["areasOfInterest"],
  });

export const adminEmailSchema = z.object({
  subject: z.string().min(1, "Add a subject line"),
  body: z.string().min(1, "Write a message"),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Enter your current password"),
    newPassword: z.string().min(8, "New password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "New passwords do not match",
    path: ["confirmPassword"],
  });

export const jobSchema = z.object({
  title: z.string().min(2, "Enter a job title"),
  employer: z.string().min(2, "Enter the employer name"),
  country: z.string().min(1, "Select a country"),
  city: z.string().optional().default(""),
  industry: z.string().optional().default(""),
  employmentType: z.string().optional().default(""),
  experienceRequired: z.string().optional().default(""),
  educationRequirement: z.string().optional().default(""),
  languageRequirement: z.string().optional().default(""),
  salary: z.string().optional().default(""),
  sponsorshipInfo: z.string().optional().default(""),
  applicationDeadline: z.string().optional().default(""),
  lastVerifiedDate: z.string().optional().default(""),
  source: z.string().optional().default(""),
  verificationStatus: z.enum(["verified", "employer_source", "government_source", "pending_verification", "expired"]),
  applicationUrl: z.string().optional().default(""),
  description: z.string().optional().default(""),
  published: z.boolean(),
});

'@
[System.IO.File]::WriteAllText("src/lib/validators.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/types" | Out-Null
$content = @'
export type Role = "admin" | "staff" | "student";

export type TargetLevel = "undergrad" | "masters" | "phd";

export type ApplicationStatus =
  | "new"
  | "documents_pending"
  | "in_review"
  | "submitted"
  | "scholarship_review"
  | "accepted"
  | "not_proceeding";

export const APPLICATION_STATUSES: { value: ApplicationStatus; label: string }[] = [
  { value: "new", label: "New" },
  { value: "documents_pending", label: "Documents pending" },
  { value: "in_review", label: "In review" },
  { value: "submitted", label: "Submitted" },
  { value: "scholarship_review", label: "Scholarship review" },
  { value: "accepted", label: "Accepted" },
  { value: "not_proceeding", label: "Not proceeding" },
];

export const TARGET_LEVELS: { value: TargetLevel; label: string }[] = [
  { value: "undergrad", label: "Undergraduate" },
  { value: "masters", label: "Master's" },
  { value: "phd", label: "PhD" },
];

export const TARGET_COUNTRIES = ["USA", "Canada", "UK", "Germany", "Other Europe", "Asia"];

export type CurrentEducationLevel = "shs_current" | "shs_graduate" | "tertiary" | "graduate" | "other";

export const CURRENT_EDUCATION_LEVELS: { value: CurrentEducationLevel; label: string }[] = [
  { value: "shs_graduate", label: "Completed Senior High School / awaiting results" },
  { value: "tertiary", label: "Currently in university / tertiary institution" },
  { value: "graduate", label: "Already completed a university degree" },
  { value: "other", label: "Other" },
];

export type ApplicationType = "standard" | "free_shs";

export interface DocumentItem {
  name: string;
  done: boolean;
  fileUrl?: string | null;
  uploadedAt?: string | null;
}

export interface UserRecord {
  id: string;
  username: string;
  email: string;
  passwordHash: string | null;
  role: Role;
  name: string;
  emailVerified: number;
  createdAt: string;
  updatedAt: string;
}

export interface StaffProfileRecord {
  id: string;
  userId: string | null;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export interface BoardMemberRecord {
  id: string;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export type ApplicationTrack = "university" | "work_visa";

export const YEARS_EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1-3 years",
  "3-5 years",
  "5-10 years",
  "10+ years",
];

export interface StudentRecord {
  id: string;
  code: string;
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string; // JSON-encoded string[]
  status: ApplicationStatus;
  assignedStaffId: string | null;
  documents: string; // JSON-encoded DocumentItem[]
  scholarshipInterest: number;
  currentEducationLevel: CurrentEducationLevel | "";
  schoolName: string;
  applicationType: ApplicationType;
  photoUrl: string | null;
  applicationTrack: ApplicationTrack;
  profession: string;
  currentOccupation: string;
  yearsExperience: string;
  hasJobOffer: number;
  phone: string;
  createdAt: string;
  updatedAt: string;
}

export interface StudentNoteRecord {
  id: string;
  studentId: string;
  authorId: string;
  text: string;
  attachmentUrl: string | null;
  createdAt: string;
}

export interface SiteContentRecord {
  id: number;
  orgName: string;
  tagline: string;
  mission: string;
  vision: string;
  contactEmail: string;
  contactPhone: string;
  address: string;
  donateInfo: string;
  logoUrl: string | null;
  heroImageUrl: string | null;
  founderName: string;
  founderTitle: string;
  founderBio: string;
  founderPhotoUrl: string | null;
  undergradInfo: string;
  mastersInfo: string;
  phdInfo: string;
  scholarshipsInfo: string;
  workVisaInfo: string;
  workVisaHeroImageUrl: string | null;
  caretakingInfo: string;
}

export interface BlogPostRecord {
  id: string;
  slug: string;
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl: string | null;
  tags: string; // JSON-encoded string[]
  authorName: string;
  published: number;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ImpactStoryRecord {
  id: string;
  studentName: string;
  headline: string;
  story: string;
  photoUrl: string | null;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: number;
  sortOrder: number;
  createdAt: string;
}

export type LeadType = "volunteer" | "donate" | "apply_interest" | "contact";

export interface VolunteerLeadRecord {
  id: string;
  type: LeadType;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  areasOfInterest: string; // JSON-encoded string[], only meaningful for type "volunteer"
  availability: string;
  handled: number;
  createdAt: string;
}

export const VOLUNTEER_AREAS = [
  "Essay review",
  "Mock interviews",
  "Mentoring a student",
  "Fundraising",
  "Event support",
  "Social media / content",
  "Other",
];

export interface SessionPayload {
  userId: string;
  role: Role;
  name: string;
}

export type NotificationType =
  | "message"
  | "document_uploaded"
  | "status_changed"
  | "student_assigned"
  | "new_student"
  | "new_lead"
  | "form_requested";

export interface NotificationRecord {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  link: string | null;
  read: number;
  createdAt: string;
}

export type JobVerificationStatus =
  | "verified"
  | "employer_source"
  | "government_source"
  | "pending_verification"
  | "expired";

export const JOB_VERIFICATION_LABELS: Record<JobVerificationStatus, string> = {
  verified: "Verified",
  employer_source: "Employer Source",
  government_source: "Government/Official Source",
  pending_verification: "Pending Verification",
  expired: "Expired",
};

export const JOB_COUNTRIES = ["USA", "Germany", "Other"];

export interface JobRecord {
  id: string;
  title: string;
  employer: string;
  country: string;
  city: string;
  industry: string;
  employmentType: string;
  experienceRequired: string;
  educationRequirement: string;
  languageRequirement: string;
  salary: string;
  sponsorshipInfo: string;
  applicationDeadline: string | null;
  lastVerifiedDate: string | null;
  source: string;
  verificationStatus: JobVerificationStatus;
  applicationUrl: string;
  description: string;
  published: number;
  createdAt: string;
  updatedAt: string;
}

export type JobApplicationStatus =
  | "saved"
  | "preparing"
  | "applied"
  | "employer_review"
  | "interview"
  | "offer_received"
  | "accepted"
  | "not_selected"
  | "withdrawn";

export const JOB_APPLICATION_STATUSES: { value: JobApplicationStatus; label: string }[] = [
  { value: "saved", label: "Saved" },
  { value: "preparing", label: "Preparing" },
  { value: "applied", label: "Applied" },
  { value: "employer_review", label: "Employer Review" },
  { value: "interview", label: "Interview" },
  { value: "offer_received", label: "Offer Received" },
  { value: "accepted", label: "Accepted" },
  { value: "not_selected", label: "Not Selected" },
  { value: "withdrawn", label: "Withdrawn" },
];

export interface JobApplicationRecord {
  id: string;
  studentId: string;
  jobId: string;
  status: JobApplicationStatus;
  notes: string;
  createdAt: string;
  updatedAt: string;
}

'@
[System.IO.File]::WriteAllText("src/types/index.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/broadcast" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { broadcastMessageAction } from "@/app/actions/admin";
import type { FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function BroadcastForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(broadcastMessageAction, initialState);

  return (
    <form action={formAction} className="space-y-5 max-w-lg">
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Send to</span>
        <select name="group" className="input" defaultValue="all">
          <option value="university">Students (university & scholarship applicants)</option>
          <option value="work_visa">Work visa applicants</option>
          <option value="all">Everyone (both groups)</option>
        </select>
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Subject</span>
        <input name="subject" required className="input" />
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Message</span>
        <textarea name="body" required rows={7} className="input" />
      </label>

      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Attachment (optional)</span>
        <input
          name="attachment"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf,.doc,.docx"
          className="input"
        />
        <span className="block text-xs text-ink/50 mt-1">Up to 8MB. Sent to every recipient.</span>
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send to group"}
      </button>
    </form>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/broadcast/broadcast-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/broadcast" | Out-Null
$content = @'
import { BroadcastForm } from "./broadcast-form";

export default function AdminBroadcastPage() {
  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Message a group</h1>
      <p className="text-ink/60 mb-8">
        Sends the same email (and an in-app notification) to everyone in the group you pick. Each person only
        sees their own copy.
      </p>
      <BroadcastForm />
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/broadcast/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/work-visa-applicants" | Out-Null
$content = @'
import { listStudentsByTrack, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "../students/student-row";

export const dynamic = "force-dynamic";

export default function AdminWorkVisaApplicantsPage() {
  const students = listStudentsByTrack("work_visa");
  const staff = listStaff();

  const rows = students.map((s) => {
    const user = getUserById(s.userId);
    return {
      id: s.id,
      userId: s.userId,
      code: s.code,
      name: user?.name || "-",
      email: user?.email || "-",
      targetLevel: s.targetLevel,
      status: s.status,
      assignedStaffId: s.assignedStaffId,
      applicationType: s.applicationType,
      schoolName: s.schoolName,
      photoUrl: s.photoUrl,
      applicationTrack: s.applicationTrack,
      profession: s.profession,
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Work Visa Applicants</h1>
      <p className="text-ink/60 mb-8">
        International Careers & Work Visa Support applicants, separate from university/scholarship students.{" "}
        <a href="/admin/students" className="text-teal hover:underline">
          View students &rarr;
        </a>
      </p>

      <div className="overflow-x-auto border border-line rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
              <th className="py-3 px-4 font-medium"></th>
              <th className="py-3 px-4 font-medium">Code</th>
              <th className="py-3 px-4 font-medium">Applicant</th>
              <th className="py-3 px-4 font-medium">Program</th>
              <th className="py-3 px-4 font-medium">Profession</th>
              <th className="py-3 px-4 font-medium">Status</th>
              <th className="py-3 px-4 font-medium">Assigned staff</th>
              <th className="py-3 px-4 font-medium"></th>
            </tr>
          </thead>
          <tbody className="px-4">
            {rows.length === 0 && (
              <tr>
                <td colSpan={8} className="py-6 px-4 text-ink/50 italic">
                  No work visa applicants have registered yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <StudentRow key={r.id} student={r} staffOptions={staff.map((s) => ({ id: s.id, name: s.name }))} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/work-visa-applicants/page.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Add phone field to registration, separate work-visa applicants in admin, add group broadcast messaging"
git push

Write-Host 'Done. Files written and pushed.'