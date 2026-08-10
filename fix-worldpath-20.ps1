# WorldPath Group - combined: (1) the comprehensive garbled-character fix
# from before, and (2) every notification now also sends an email copy,
# so people don't have to be actively watching the portal.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/about" | Out-Null
$content = @'
import { getSiteContent, listStaff, listBoardMembers } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AboutPage() {
  const content = getSiteContent();
  const staff = listStaff();
  const board = listBoardMembers();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">About us</p>
          <h1 className="font-display text-4xl mt-4 max-w-2xl">Who's behind {content.orgName}</h1>
          <p className="mt-6 text-lg text-ink/80 max-w-2xl">{content.mission}</p>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-teal font-medium mb-2">Day to day</p>
          <h2 className="font-display text-2xl mb-8">Staff directory</h2>
          {staff.length === 0 ? (
            <EmptyNote text="Staff profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {staff.map((s) => (
                <PersonCard key={s.id} name={s.name} title={s.title} bio={s.bio} photoUrl={s.photoUrl} variant="staff" />
              ))}
            </div>
          )}
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-2">Governance</p>
          <h2 className="font-display text-2xl mb-8">Board of Directors</h2>
          {board.length === 0 ? (
            <EmptyNote text="Board member profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {board.map((b) => (
                <PersonCard key={b.id} name={b.name} title={b.title} bio={b.bio} photoUrl={b.photoUrl} variant="board" />
              ))}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

function PersonCard({
  name,
  title,
  bio,
  photoUrl,
  variant,
}: {
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  variant: "staff" | "board";
}) {
  const isBoard = variant === "board";
  return (
    <div
      className={`rounded-xl p-6 border ${
        isBoard ? "border-gold-deep/30 bg-gold/5" : "border-line"
      }`}
    >
      <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden mb-4">
        {photoUrl ? (
          <PhotoLightbox src={photoUrl} alt={name} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full grid place-items-center">
            <span className="font-display text-2xl">{name.charAt(0)}</span>
          </div>
        )}
      </div>
      <h3 className="font-display text-lg">{name}</h3>
      <p className={`text-sm mb-2 ${isBoard ? "text-gold-deep" : "text-teal"}`}>
        {isBoard ? "Board &middot; " : ""}
        {title}
      </p>
      <p className="text-sm text-ink/70 leading-relaxed">{bio}</p>
    </div>
  );
}

function EmptyNote({ text }: { text: string }) {
  return <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">{text}</p>;
}


'@
[System.IO.File]::WriteAllText("src/app/about/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/account" | Out-Null
$content = @'
import Link from "next/link";
import { getSession } from "@/lib/auth";
import { logoutAction } from "@/app/actions/auth";
import { BackArrowIcon } from "@/components/back-arrow-icon";
import { ChangePasswordForm } from "./change-password-form";

export default async function AccountPage() {
  const session = await getSession();

  return (
    <>
      <header className="border-b border-line">
        <div className="mx-auto max-w-3xl px-6 h-16 flex items-center justify-between">
          <Link href="/" className="font-display text-lg">
            WorldPath
          </Link>
          <div className="flex items-center gap-4 text-sm">
            {session && (
              <Link href={`/${session.role}`} className="text-teal hover:underline">
                <BackArrowIcon className="w-3.5 h-3.5 inline" /> Back to dashboard
              </Link>
            )}
            <form action={logoutAction}>
              <button className="text-teal hover:underline">Log out</button>
            </form>
          </div>
        </div>
      </header>
      <main className="flex-1 mx-auto max-w-3xl w-full px-6 py-10">
        <h1 className="font-display text-3xl mb-2">Account settings</h1>
        <p className="text-ink/60 mb-8">
          Signed in as {session?.name} ({session?.role}).
        </p>
        <h2 className="text-lg font-medium mb-4">Change password</h2>
        <ChangePasswordForm />
      </main>
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/account/page.tsx", $content, $Utf8NoBom)

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
    logoUrl,
    heroImageUrl,
    founderPhotoUrl,
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


'@
[System.IO.File]::WriteAllText("src/app/actions/admin.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { redirect } from "next/navigation";
import { randomBytes } from "node:crypto";
import bcrypt from "bcryptjs";
import { registerSchema, freeRegisterSchema, loginSchema } from "@/lib/validators";
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
  });

  await notifyAllAdmins({
    type: "new_student",
    title: "New free application registered",
    body: `${user.name} registered through the Wesley SHS free program.`,
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

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { createLead, markLeadHandled } from "@/lib/repo";
import { notifyAllAdmins } from "@/lib/notify";
import { leadSchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

export async function submitLeadAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const parsed = leadSchema.safeParse({
    type: String(formData.get("type") || "volunteer"),
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    message: String(formData.get("message") || ""),
    areasOfInterest: formData.getAll("areasOfInterest").map(String),
    availability: String(formData.get("availability") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  createLead(parsed.data);

  const typeLabel = parsed.data.type === "donate" ? "Donate inquiry" : parsed.data.type === "contact" ? "Contact form" : "Volunteer";
  await notifyAllAdmins({
    type: "new_lead",
    title: `New ${typeLabel.toLowerCase()} submission`,
    body: `${parsed.data.name} (${parsed.data.email})`,
    link: "/admin/leads",
  });

 return { success: "Thanks - we'll be in touch soon." };
}

export async function markLeadHandledAction(formData: FormData) {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  const id = String(formData.get("id") || "");
  const handled = formData.get("handled") === "true";
  markLeadHandled(id, handled);
  revalidatePath("/admin/leads");
}


'@
[System.IO.File]::WriteAllText("src/app/actions/leads.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import {
  getStaffByUserId,
  getStudentById,
  updateStudentStatus,
  updateStudentDocuments,
  addNote,
} from "@/lib/repo";
import { notifyUser } from "@/lib/notify";
import { APPLICATION_STATUSES } from "@/types";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";

async function requireOwningStaff(studentId: string) {
  const session = await getSession();
  if (!session || session.role !== "staff") {
    throw new Error("Not authorized");
  }
  const staff = getStaffByUserId(session.userId);
  const student = getStudentById(studentId);
  if (!staff || !student || student.assignedStaffId !== staff.id) {
    throw new Error("Not authorized for this student");
  }
  return { session, staff, student };
}

export async function staffUpdateStatusAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  const { student } = await requireOwningStaff(studentId);
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);

  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === status)?.label ?? status;
  await notifyUser({
    userId: student.userId,
    type: "status_changed",
    title: "Your application status changed",
    body: `Your status is now "${statusLabel}".`,
    link: "/student",
  });

  revalidatePath(`/staff/students/${studentId}`);
  revalidatePath("/staff");
}

export async function staffToggleDocumentAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  const index = Number(formData.get("index") || 0);
  const { student } = await requireOwningStaff(studentId);
  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (docs[index]) {
    docs[index] = { ...docs[index], done: !docs[index].done };
  }
  updateStudentDocuments(studentId, docs);
  revalidatePath(`/staff/students/${studentId}`);
}

export async function staffAddNoteAction(
  studentId: string,
  _prev: FormState,
  formData: FormData
): Promise<FormState> {
  const { session, student } = await requireOwningStaff(studentId);
  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachmentFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (attachmentFile instanceof File && attachmentFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedDocument(attachmentFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a note or attach a file." };
  }

  addNote(studentId, session.userId, parsed.data.text.trim(), attachmentUrl);

  await notifyUser({
    userId: student.userId,
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
    link: "/student",
  });

  revalidatePath(`/staff/students/${studentId}`);
  return { success: "Note added." };
}

'@
[System.IO.File]::WriteAllText("src/app/actions/staff.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { getStudentByUserId, updateStudentDocuments, addNote, getStaffById } from "@/lib/repo";
import { notifyUser } from "@/lib/notify";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError, deleteUploadedImage } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";
export type { FormState } from "@/app/actions/auth";

async function requireOwnStudentRecord() {
  const session = await getSession();
  if (!session || session.role !== "student") {
    throw new Error("Not authorized");
  }
  const student = getStudentByUserId(session.userId);
  if (!student) {
    throw new Error("No application record found");
  }
  return { session, student };
}

async function notifyAssignedStaff(
  assignedStaffId: string | null,
  studentId: string,
  input: { type: "message" | "document_uploaded" | "form_requested"; title: string; body: string }
) {
  if (!assignedStaffId) return;
  const staff = getStaffById(assignedStaffId);
  if (!staff?.userId) return;
  await notifyUser({
    userId: staff.userId,
    type: input.type,
    title: input.title,
    body: input.body,
    link: `/staff/students/${studentId}`,
  });
}

export async function studentUploadDocumentAction(formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();
  const index = Number(formData.get("index") || -1);
  const file = formData.get("file");

  if (!(file instanceof File) || file.size === 0) {
    return { error: "Please choose a file first." };
  }

  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (!docs[index]) {
    return { error: "That document slot doesn't exist." };
  }

  let fileUrl: string;
  try {
    fileUrl = await saveUploadedDocument(file);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (docs[index].fileUrl) await deleteUploadedImage(docs[index].fileUrl);

  docs[index] = { ...docs[index], fileUrl, done: true, uploadedAt: new Date().toISOString() };
  updateStudentDocuments(student.id, docs);

  await notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "document_uploaded",
    title: `${session.name} uploaded a document`,
    body: docs[index].name,
  });

  revalidatePath("/student");
  return { success: "Document uploaded." };
}

export async function studentAddNoteAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachmentFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (attachmentFile instanceof File && attachmentFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedDocument(attachmentFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a message or attach a file." };
  }

  addNote(student.id, session.userId, parsed.data.text.trim(), attachmentUrl);

  await notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
  });

  revalidatePath("/student");
  return { success: "Message sent." };
}

/**
 * Standard (non-free) applicants request their application form from their
 * assigned counselor, rather than getting one automatically. This notifies
 * the counselor and drops a message in the shared thread so there's a
 * record of the request; the counselor replies with the form as a message
 * attachment.
 */
export async function requestApplicationFormAction(): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  if (student.applicationType !== "standard") {
    return { error: "This is only needed for standard applications." };
  }
  if (!student.assignedStaffId) {
    return { error: "You don't have a counselor assigned yet. Please check back soon." };
  }

  const staff = getStaffById(student.assignedStaffId);
  if (!staff?.userId) {
    return { error: "Your counselor doesn't have an active account yet. Please check back soon." };
  }

  addNote(student.id, session.userId, "Requested the application form.");

  await notifyUser({
    userId: staff.userId,
    type: "form_requested",
    title: `${session.name} requested the application form`,
    body: "Reply in their message thread with the form attached.",
    link: `/staff/students/${student.id}`,
  });

  revalidatePath("/student");
  return { success: "Request sent to your counselor." };
}

'@
[System.IO.File]::WriteAllText("src/app/actions/student.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/blog" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { saveBlogPostAction, type FormState } from "@/app/actions/blog";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function BlogPostForm({
  post,
}: {
  post?: {
    id: string;
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl: string | null;
    tags: string;
    authorName: string;
    published: number;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(saveBlogPostAction, {});
  const tags = post ? (JSON.parse(post.tags) as string[]).join(", ") : "";

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      {post && <input type="hidden" name="id" value={post.id} />}

      <div>
        <span className="block text-sm font-medium mb-1.5">Cover image (optional)</span>
        <PhotoUploadField
          existingUrl={post?.coverImageUrl}
          name="cover"
          hiddenFieldName="existingCoverUrl"
          shape="rect"
        />
      </div>

      <Field label="Title">
        <input name="title" defaultValue={post?.title} required className="input" placeholder="e.g. How to apply for a need-based scholarship in the US" />
      </Field>

      <Field label="Excerpt (shown in previews and search results)">
        <textarea name="excerpt" defaultValue={post?.excerpt} required rows={2} className="input" />
      </Field>

      <Field label="Body (Markdown supported - headings, **bold**, lists, links)">
        <textarea name="body" defaultValue={post?.body} required rows={16} className="input font-mono text-sm" />
      </Field>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Author name">
          <input name="authorName" defaultValue={post?.authorName || "WorldPath Group"} required className="input" />
        </Field>
        <Field label="Tags (comma-separated)">
          <input name="tags" defaultValue={tags} className="input" placeholder="scholarships, USA, essays" />
        </Field>
      </div>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="published" defaultChecked={post ? post.published === 1 : false} className="accent-teal" />
        Published (visible on the public blog)
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : post ? "Save changes" : "Create post"}
      </button>
    </form>
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
[System.IO.File]::WriteAllText("src/app/admin/blog/blog-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/blog" | Out-Null
$content = @'
import Link from "next/link";
import { listAllPosts } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteBlogPostAction } from "@/app/actions/blog";

export const dynamic = "force-dynamic";

export default function AdminBlogPage() {
  const posts = listAllPosts();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Blog</h1>
          <p className="text-ink/60">Success stories and application guides for organic search traffic.</p>
        </div>
        <Link href="/admin/blog/new" className="btn-primary">
          + New post
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {posts.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No posts yet.</p>}
        {posts.map((p) => (
          <div key={p.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">{p.title}</p>
              <p className="text-xs text-ink/50">
                {p.published ? (
                  <span className="text-teal">Published</span>
                ) : (
                  <span className="text-gold-deep">Draft</span>
                )}
                {" \u00b7 "}
                /blog/{p.slug}
              </p>
            </div>
            <div className="flex items-center gap-4 text-sm shrink-0">
              <Link href={`/admin/blog/${p.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={p.id} action={deleteBlogPostAction} confirmLabel={`Delete "${p.title}"?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/blog/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/content" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { updateSiteContentAction, type FormState } from "@/app/actions/admin";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function ContentForm({
  content,
}: {
  content: {
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
    caretakingInfo: string;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateSiteContentAction, {});

  return (
    <form action={formAction} className="space-y-8 max-w-2xl">
      <Section title="Branding">
        <div>
          <span className="block text-sm font-medium mb-1.5">Logo (shown in the site header)</span>
          <PhotoUploadField existingUrl={content.logoUrl} name="logo" hiddenFieldName="existingLogoUrl" />
        </div>

        <div>
          <span className="block text-sm font-medium mb-1.5">
            Homepage hero background (the dark banner behind the headline)
          </span>
          <PhotoUploadField
            existingUrl={content.heroImageUrl}
            name="hero"
            hiddenFieldName="existingHeroImageUrl"
            shape="rect"
          />
          <p className="text-xs text-ink/50 mt-1.5">
            A wide photo works best. It's shown with a dark overlay so the headline text stays readable.
            Leave empty to keep the plain navy background.
          </p>
        </div>
      </Section>

      <Section title="Organization">
        <Field label="Organization name">
          <input name="orgName" defaultValue={content.orgName} required className="input" />
        </Field>
        <Field label="Tagline">
          <input name="tagline" defaultValue={content.tagline} required className="input" />
        </Field>
        <Field label="Mission">
          <textarea name="mission" defaultValue={content.mission} required rows={4} className="input" />
        </Field>
        <Field label="Vision">
          <textarea name="vision" defaultValue={content.vision} required rows={3} className="input" />
        </Field>
      </Section>

      <Section title="Founder">
        <div>
          <span className="block text-sm font-medium mb-1.5">Founder photo</span>
          <PhotoUploadField
            existingUrl={content.founderPhotoUrl}
            name="founderPhoto"
            hiddenFieldName="existingFounderPhotoUrl"
          />
        </div>
        <div className="grid sm:grid-cols-2 gap-5">
          <Field label="Name">
            <input name="founderName" defaultValue={content.founderName} className="input" />
          </Field>
          <Field label="Title">
            <input name="founderTitle" defaultValue={content.founderTitle} className="input" />
          </Field>
        </div>
        <Field label="Short bio">
          <textarea name="founderBio" defaultValue={content.founderBio} rows={3} className="input" />
        </Field>
      </Section>

      <Section title="Program pages">
        <p className="text-xs text-ink/50 -mt-2">
          Each of these becomes its own page (e.g. worldpathgroup.org/programs/undergraduate). Leave a field
          empty and that page shows a simple default message instead.
        </p>
        <Field label="Undergraduate applications">
          <textarea name="undergradInfo" defaultValue={content.undergradInfo} rows={4} className="input" />
        </Field>
        <Field label="Master's applications">
          <textarea name="mastersInfo" defaultValue={content.mastersInfo} rows={4} className="input" />
        </Field>
        <Field label="PhD applications">
          <textarea name="phdInfo" defaultValue={content.phdInfo} rows={4} className="input" />
        </Field>
        <Field label="Scholarships">
          <textarea name="scholarshipsInfo" defaultValue={content.scholarshipsInfo} rows={4} className="input" />
        </Field>
      </Section>

      <Section title="WorldPath Caretaking Foundation">
        <Field label="Description (projects, partnerships - shown on the homepage and the Foundation page)">
          <textarea
            name="caretakingInfo"
            defaultValue={content.caretakingInfo}
            rows={5}
            className="input"
            placeholder="Describe your caretaking projects and partnerships, e.g. work with God Matters Fellowship..."
          />
        </Field>
      </Section>

      <Section title="Contact">
        <div className="grid sm:grid-cols-2 gap-5">
          <Field label="Contact email">
            <input name="contactEmail" type="email" defaultValue={content.contactEmail} required className="input" />
          </Field>
          <Field label="Contact phone (one or more, any format)">
            <input name="contactPhone" defaultValue={content.contactPhone} className="input" placeholder="e.g. 0530901898 / 0509878889" />
          </Field>
        </div>
        <Field label="Address (one location per line)">
          <textarea
            name="address"
            defaultValue={content.address}
            rows={3}
            className="input"
            placeholder={"Konongo\nP.O. Box 87\nAccra, Legon"}
          />
        </Field>
      </Section>

      <Section title="Donate">
        <Field label="Donate details (bank account / mobile money - shown on the Get Involved page)">
          <textarea name="donateInfo" defaultValue={content.donateInfo} rows={4} className="input" />
        </Field>
      </Section>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Save changes"}
      </button>
    </form>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="pt-6 first:pt-0 border-t border-line first:border-0">
      <h2 className="font-display text-lg mb-4">{title}</h2>
      <div className="space-y-5">{children}</div>
    </div>
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
[System.IO.File]::WriteAllText("src/app/admin/content/content-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/content" | Out-Null
$content = @'
import { getSiteContent } from "@/lib/repo";
import { ContentForm } from "./content-form";

export const dynamic = "force-dynamic";

export default function AdminContentPage() {
  const content = getSiteContent();
  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Site content</h1>
      <p className="text-ink/60 mb-8">
        Edit what visitors see on the homepage and about page - no code required.
      </p>
      <ContentForm content={content} />
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/content/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/leads" | Out-Null
$content = @'
import { listLeads } from "@/lib/repo";
import { HandledToggle } from "./handled-toggle";

export const dynamic = "force-dynamic";

const TYPE_LABEL: Record<string, string> = {
  volunteer: "Volunteer",
  donate: "Donate inquiry",
  apply_interest: "Apply interest",
  contact: "Contact form",
};

export default function AdminLeadsPage() {
  const leads = listLeads();
  const open = leads.filter((l) => !l.handled);

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Leads</h1>
      <p className="text-ink/60 mb-8">
        Volunteer and donation inquiries submitted from the Get Involved page. {open.length} awaiting a reply.
      </p>

      <div className="divide-y divide-line border border-line rounded-xl">
        {leads.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No inquiries yet.</p>}
        {leads.map((l) => {
          const areas = l.areasOfInterest ? (JSON.parse(l.areasOfInterest) as string[]) : [];
          return (
            <div key={l.id} className={`p-4 ${l.handled ? "opacity-60" : ""}`}>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium">
                    {l.name} <span className="text-xs uppercase text-gold-deep ml-2">{TYPE_LABEL[l.type] ?? l.type}</span>
                  </p>
                  <p className="text-sm text-ink/60">
                    {l.email}
                    {l.phone ? ` \u00b7 ${l.phone}` : ""}
                  </p>
                  {areas.length > 0 && (
                    <p className="text-sm text-teal mt-2">{areas.join(" \u00b7 ")}</p>
                  )}
                  {l.availability && <p className="text-sm text-ink/60 mt-1">Availability: {l.availability}</p>}
                  {l.message && <p className="text-sm text-ink/80 mt-2 max-w-xl">{l.message}</p>}
                  <p className="text-xs text-ink/40 mt-2">{new Date(l.createdAt).toLocaleString()}</p>
                </div>
                <HandledToggle id={l.id} handled={l.handled === 1} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/leads/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/staff/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getStaffById, getUserById } from "@/lib/repo";
import { StaffForm } from "../staff-form";
import { EmailStaffForm } from "./email-staff-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";

export const dynamic = "force-dynamic";

export default async function EditStaffPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const staff = getStaffById(id);
  if (!staff) notFound();

  const user = staff.userId ? getUserById(staff.userId) : undefined;

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit staff member</h1>
      <StaffForm staff={staff} />

      <div className="mt-12 pt-8 border-t border-line max-w-lg">
        <h2 className="font-display text-xl mb-4">Email this staff member</h2>
        {user ? (
          <EmailStaffForm staffId={staff.id} staffEmail={user.email} />
        ) : (
          <p className="text-sm text-ink/50 italic">
            No linked login account yet - nothing to email. Create one from the Accounts page.
          </p>
        )}
      </div>

      {user && (
        <div className="mt-12 pt-8 border-t border-line max-w-lg">
          <h2 className="font-display text-xl mb-2 text-red-700">Danger zone</h2>
          <p className="text-sm text-ink/60 mb-4">
            Deletes {user.name}'s login and this staff profile. Any assigned students become unassigned.
            This can't be undone.
          </p>
          <DeleteButton
            id={user.id}
            action={deleteUserAction}
            confirmLabel={`Delete ${user.name}'s account? This removes their login and this staff profile. This can't be undone.`}
          />
        </div>
      )}
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/staff/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getStudentById, getUserById, listNotesForStudent, listStaff } from "@/lib/repo";
import { APPLICATION_STATUSES, CURRENT_EDUCATION_LEVELS } from "@/types";
import type { DocumentItem } from "@/types";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { MessageThread } from "@/components/message-thread";
import { EmailStudentForm } from "./email-student-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";
import { CheckIcon } from "@/components/check-icon";

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
          value={student.applicationType === "free_shs" ? "Free &middot; SHS partnership" : "Standard"}
        />
        <InfoCard label="Targeting" value={`${student.targetLevel} - ${targetCountries.join(", ")}`} />
        <InfoCard label="Current education" value={`${eduLabel}${student.schoolName ? ` (${student.schoolName})` : ""}`} />
        <InfoCard label="Assigned counselor" value={assignedStaff?.name || "Unassigned"} />
        <InfoCard label="Applied" value={new Date(student.createdAt).toLocaleDateString()} />
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
import { listStudents, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "./student-row";

export const dynamic = "force-dynamic";

export default function AdminStudentsPage() {
  const students = listStudents();
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
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Students</h1>
      <p className="text-ink/60 mb-8">Every student record across the organization. Changes save instantly.</p>

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

New-Item -ItemType Directory -Force -Path "src/app/admin/students" | Out-Null
$content = @'
"use client";

import { useRef } from "react";
import Link from "next/link";
import { assignStudentAction, adminUpdateStatusAction, deleteUserAction } from "@/app/actions/admin";
import { APPLICATION_STATUSES } from "@/types";
import { PhotoLightbox } from "@/components/photo-lightbox";
import { DeleteButton } from "@/components/delete-button";

export function StudentRow({
  student,
  staffOptions,
}: {
  student: {
    id: string;
    userId: string;
    code: string;
    name: string;
    email: string;
    targetLevel: string;
    status: string;
    assignedStaffId: string | null;
    applicationType: string;
    schoolName: string;
    photoUrl: string | null;
  };
  staffOptions: { id: string; name: string }[];
}) {
  const assignFormRef = useRef<HTMLFormElement>(null);
  const statusFormRef = useRef<HTMLFormElement>(null);

  return (
    <tr className="border-b border-line last:border-0">
      <td className="py-3 pl-4 pr-2">
        <div className="w-9 h-9 rounded-full bg-paper-dim border border-line overflow-hidden">
          {student.photoUrl ? (
            <PhotoLightbox src={student.photoUrl} alt={student.name} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-xs text-ink/40">{student.name.charAt(0)}</div>
          )}
        </div>
      </td>
      <td className="py-3 pr-4">
        <span className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1">{student.code}</span>
      </td>
      <td className="py-3 pr-4">
        <p className="font-medium">{student.name}</p>
        <p className="text-xs text-ink/50">{student.email}</p>
      </td>
      <td className="py-3 pr-4">
        {student.applicationType === "free_shs" ? (
          <>
            <span className="text-xs uppercase tracking-wide text-gold-deep font-medium">Free &middot; SHS</span>
            {student.schoolName && <p className="text-xs text-ink/50 mt-0.5">{student.schoolName}</p>}
          </>
        ) : (
          <span className="text-xs text-ink/50">Standard</span>
        )}
      </td>
      <td className="py-3 pr-4 text-sm capitalize">{student.targetLevel}</td>
      <td className="py-3 pr-4">
        <form ref={statusFormRef} action={adminUpdateStatusAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="status"
            defaultValue={student.status}
            className="input py-1.5 text-xs"
            onChange={() => statusFormRef.current?.requestSubmit()}
          >
            {APPLICATION_STATUSES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </form>
      </td>
      <td className="py-3 pr-4">
        <form ref={assignFormRef} action={assignStudentAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="staffId"
            defaultValue={student.assignedStaffId ?? ""}
            className="input py-1.5 text-xs"
            onChange={() => assignFormRef.current?.requestSubmit()}
          >
            <option value="">Unassigned</option>
            {staffOptions.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </form>
      </td>
      <td className="py-3 pr-4 text-right">
        <div className="flex items-center justify-end gap-3">
          <Link href={`/admin/students/${student.id}`} className="text-teal hover:underline text-xs">
            Details
          </Link>
          <DeleteButton
            id={student.userId}
            action={deleteUserAction}
            confirmLabel={`Delete ${student.name}'s account? This removes their login and entire application record. This can't be undone.`}
          />
        </div>
      </td>
    </tr>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/students/student-row.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/users" | Out-Null
$content = @'
import { listUsers } from "@/lib/repo";
import { getSession } from "@/lib/auth";
import { CreateStaffUserForm } from "./create-staff-form";
import { DeleteButton } from "@/components/delete-button";
import { deleteUserAction } from "@/app/actions/admin";

export const dynamic = "force-dynamic";

export default async function AdminUsersPage() {
  const users = listUsers();
  const session = await getSession();
  const adminCount = users.filter((u) => u.role === "admin").length;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Accounts</h1>
      <p className="text-ink/60 mb-8">
        All admin, staff, and student accounts. Create new staff logins here. Deleting an account removes
        its login and any linked profile - staff and student records included.
      </p>

      <div className="grid lg:grid-cols-2 gap-10">
        <div className="overflow-x-auto border border-line rounded-xl h-fit">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
                <th className="py-3 px-4 font-medium">Name</th>
                <th className="py-3 px-4 font-medium">Email</th>
                <th className="py-3 px-4 font-medium">Role</th>
                <th className="py-3 px-4 font-medium">Verified</th>
                <th className="py-3 px-4 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => {
                const isSelf = u.id === session?.userId;
                const isLastAdmin = u.role === "admin" && adminCount <= 1;
                return (
                  <tr key={u.id} className="border-b border-line last:border-0">
                    <td className="py-3 px-4">{u.name}</td>
                    <td className="py-3 px-4 text-ink/60">{u.email}</td>
                    <td className="py-3 px-4 capitalize">{u.role}</td>
                    <td className="py-3 px-4">{u.emailVerified ? "Yes" : "Pending"}</td>
                    <td className="py-3 px-4 text-right">
                      {isSelf ? (
                        <span className="text-xs text-ink/30">You</span>
                      ) : isLastAdmin ? (
                        <span className="text-xs text-ink/30">Last admin</span>
                      ) : (
                        <DeleteButton
                          id={u.id}
                          action={deleteUserAction}
                          confirmLabel={`Delete ${u.name}'s account? This removes their login and any linked staff or student record. This can't be undone.`}
                        />
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <CreateStaffUserForm />
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/users/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/blog/[slug]" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { marked } from "marked";
import { getSiteContent, getPostBySlug } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { BackArrowIcon } from "@/components/back-arrow-icon";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post || post.published !== 1) return {};

  return {
    title: `${post.title} | Blog`,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: "article",
      publishedTime: post.publishedAt || undefined,
      images: post.coverImageUrl ? [post.coverImageUrl] : undefined,
    },
  };
}

export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const content = getSiteContent();
  const post = getPostBySlug(slug);

  if (!post || post.published !== 1) notFound();

  const tags = JSON.parse(post.tags) as string[];
  const html = marked.parse(post.body, { async: false }) as string;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    description: post.excerpt,
    author: { "@type": "Person", name: post.authorName },
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    image: post.coverImageUrl || undefined,
  };

  return (
    <>
      {/* eslint-disable-next-line react/no-danger */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <article className="mx-auto max-w-2xl px-6 pt-16 pb-24">
          <Link href="/blog" className="text-sm text-teal hover:underline">
            <BackArrowIcon className="w-3.5 h-3.5 inline" /> Back to blog
          </Link>

          {tags.length > 0 && (
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mt-6">{tags.join(" \u00b7 ")}</p>
          )}
          <h1 className="font-display text-3xl sm:text-4xl mt-3 mb-4">{post.title}</h1>
          <p className="text-sm text-ink/50 mb-8">
            {post.authorName}
            {post.publishedAt ? ` \u00b7 ${new Date(post.publishedAt).toLocaleDateString()}` : ""}
          </p>

          {post.coverImageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={post.coverImageUrl} alt={post.title} className="w-full rounded-xl mb-10 object-cover max-h-96" />
          )}

          <div
            className="prose-content text-ink/85 leading-relaxed"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: html }}
          />

          <div className="mt-14 pt-8 border-t border-line flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <p className="text-ink/70">Ready to start your own application?</p>
            <Link href="/register" className="btn-primary shrink-0 text-center">
              Apply now
            </Link>
          </div>
        </article>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/blog/[slug]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/blog" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listPublishedPosts } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Blog | ${content.orgName}`,
    description: "Student success stories and guides to applying for university and scholarships abroad.",
  };
}

export default function BlogIndexPage() {
  const content = getSiteContent();
  const posts = listPublishedPosts();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.25em] text-xs text-gold-deep font-medium">Blog</p>
          <h1 className="font-display text-4xl sm:text-5xl mt-5">Guides & stories</h1>
          <p className="mt-6 text-lg text-ink/70 max-w-xl">
            Application guides, scholarship tips, and stories from students on their way abroad.
          </p>
        </section>

        <section className="mx-auto max-w-5xl px-6 pb-20">
          {posts.length === 0 ? (
            <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
 No posts published yet - check back soon.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-8">
              {posts.map((p) => {
                const tags = JSON.parse(p.tags) as string[];
                return (
                  <Link
                    key={p.id}
                    href={`/blog/${p.slug}`}
                    className="border border-line rounded-xl overflow-hidden hover:border-gold-deep/60 hover:shadow-sm transition-all flex flex-col"
                  >
                    {p.coverImageUrl && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={p.coverImageUrl} alt={p.title} className="w-full h-40 object-cover" />
                    )}
                    <div className="p-6 flex-1 flex flex-col">
                      {tags.length > 0 && (
                        <p className="text-xs uppercase tracking-wide text-gold-deep mb-2">{tags[0]}</p>
                      )}
                      <h2 className="font-display text-xl mb-2">{p.title}</h2>
                      <p className="text-sm text-ink/70 leading-relaxed flex-1">{p.excerpt}</p>
                      <p className="text-xs text-ink/40 mt-4">
                        {p.publishedAt ? new Date(p.publishedAt).toLocaleDateString() : ""} &middot; {p.authorName}
                      </p>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/blog/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/impact" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listStudents, listImpactStories, listStaff } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Our Impact | ${content.orgName}`,
    description:
      "Real numbers and real student stories from WorldPath Group's work helping Ghanaian students reach university and scholarships abroad.",
  };
}

export default function ImpactPage() {
  const content = getSiteContent();
  const studentCount = listStudents().length;
  const staffCount = listStaff().length;
  const stories = listImpactStories();
  const featured = stories.filter((s) => s.featured === 1);
  const rest = stories.filter((s) => s.featured !== 1);
  const ordered = [...featured, ...rest];

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="bg-navy text-paper">
          <div className="mx-auto max-w-5xl px-6 pt-20 pb-16 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">Our impact</p>
            <h1 className="font-display text-4xl sm:text-5xl mt-5">Real students. Real universities.</h1>
            <p className="mt-6 text-lg text-paper/75 max-w-xl mx-auto">
 Every number here reflects a student who is currently in our program right now - not a
              marketing estimate.
            </p>
          </div>
        </section>

        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-8 text-center">
            <Stat value={studentCount} label="Students currently in the program" />
            <Stat value={staffCount} label="Counselors working with them" />
            <Stat value="5" label="Study destinations we cover" />
            <Stat value="Free" label="Application help via Wesley SHS" />
          </div>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Student stories</p>
          <h2 className="font-display text-3xl mb-10">In their own words</h2>

          {ordered.length === 0 ? (
            <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
              Student stories will appear here as they're added from the admin portal.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-8">
              {ordered.map((s) => (
                <article key={s.id} className="border border-line rounded-xl p-6">
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-12 h-12 rounded-full bg-paper-dim border border-line grid place-items-center overflow-hidden shrink-0">
                      {s.photoUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={s.photoUrl} alt={s.studentName} className="w-full h-full object-cover" />
                      ) : (
                        <span className="font-display">{s.studentName.charAt(0)}</span>
                      )}
                    </div>
                    <div>
                      <p className="font-medium">{s.studentName}</p>
                      <p className="text-xs text-gold-deep uppercase tracking-wide">
                        {s.destinationCountry} &middot; {s.targetLevel}
                      </p>
                    </div>
                  </div>
                  <h3 className="font-display text-lg mb-2">{s.headline}</h3>
                  <p className="text-sm text-ink/70 leading-relaxed">{s.story}</p>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-2xl mb-2">Help us reach more students</h2>
              <p className="text-paper/75 max-w-lg">
                Every counselor, every scholarship search, every application costs time and money we
                raise from people who believe in this work.
              </p>
            </div>
            <Link href="/get-involved" className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Get involved
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

function Stat({ value, label }: { value: string | number; label: string }) {
  return (
    <div>
      <p className="font-display text-3xl sm:text-4xl text-gold-deep">{value}</p>
      <p className="text-xs sm:text-sm text-ink/60 mt-1">{label}</p>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/impact/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/register/check-email" | Out-Null
$content = @'
import { CheckIcon } from "@/components/check-icon";

export default async function CheckEmailPage({
  searchParams,
}: {
  searchParams: Promise<{ email?: string }>;
}) {
  const { email } = await searchParams;

  return (
    <main className="flex-1 flex items-center justify-center px-6 py-16">
      <div className="max-w-md text-center">
        <span className="inline-grid place-items-center w-14 h-14 rounded-full bg-teal/10 text-teal mb-6">
          <CheckIcon className="w-6 h-6" />
        </span>
        <h1 className="font-display text-2xl mb-3">Check your email</h1>
        <p className="text-ink/70 leading-relaxed">
          We've sent a verification link to <strong>{email || "your email address"}</strong>. Open it to
          verify your account and set your password.
        </p>
        <p className="text-xs text-ink/40 mt-6">
          Running locally without email configured? The link is printed to the server console.
        </p>
      </div>
    </main>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/register/check-email/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
$content = @'
"use client";

import { staffToggleDocumentAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";
import { CheckIcon } from "@/components/check-icon";

export function DocumentChecklist({ studentId, documents }: { studentId: string; documents: DocumentItem[] }) {
  return (
    <ul className="space-y-2">
      {documents.map((doc, index) => (
        <li key={doc.name} className="flex items-center gap-2">
          <form action={staffToggleDocumentAction} className="flex-1">
            <input type="hidden" name="studentId" value={studentId} />
            <input type="hidden" name="index" value={index} />
            <button
              type="submit"
              className="w-full flex items-center gap-3 border border-line rounded-lg px-3 py-2 text-sm hover:border-ink transition-colors text-left"
            >
              <span
                className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
                  doc.done ? "bg-teal border-teal text-white" : "border-line"
                }`}
              >
                {doc.done ? <CheckIcon className="w-3 h-3" /> : null}
              </span>
              <span className={`truncate ${doc.done ? "line-through text-ink/50" : ""}`}>{doc.name}</span>
            </button>
          </form>
          {doc.fileUrl && (
            <a
              href={doc.fileUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-teal hover:underline shrink-0"
            >
              View file
            </a>
          )}
        </li>
      ))}
    </ul>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/staff/students/[id]/document-checklist.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
"use client";

import { useRef, useState, useTransition } from "react";
import { studentUploadDocumentAction } from "@/app/actions/student";
import type { DocumentItem } from "@/types";
import { CheckIcon } from "@/components/check-icon";

export function DocumentUploadRow({ doc, index }: { doc: DocumentItem; index: number }) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    const formData = new FormData();
    formData.set("index", String(index));
    formData.set("file", file);
    startTransition(async () => {
      const result = await studentUploadDocumentAction(formData);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <li className="border border-line rounded-lg px-3 py-2.5">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <span
            className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
              doc.done ? "bg-teal border-teal text-white" : "border-line"
            }`}
          >
            {doc.done ? <CheckIcon className="w-3 h-3" /> : null}
          </span>
          <span className={`text-sm truncate ${doc.done ? "" : "text-ink/80"}`}>{doc.name}</span>
        </div>
        <div className="flex items-center gap-3 shrink-0 text-xs">
          {doc.fileUrl && (
            <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-teal hover:underline">
              View
            </a>
          )}
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            disabled={pending}
            className="text-teal hover:underline disabled:opacity-60"
          >
            {pending ? "Uploading..." : doc.fileUrl ? "Replace" : "Upload"}
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif,application/pdf"
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0])}
          />
        </div>
      </div>
      {error && <p className="text-xs text-red-700 mt-1.5">{error}</p>}
    </li>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/student/document-upload-row.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import type { Role } from "@/types";

export interface ThreadMessage {
  id: string;
  text: string;
  attachmentUrl: string | null;
  authorName: string;
  authorRole: Role;
  createdAt: string;
}

export function MessageThread({ messages, viewerRole }: { messages: ThreadMessage[]; viewerRole: Role }) {
  if (messages.length === 0) {
    return <p className="text-sm text-ink/50 italic">No messages yet.</p>;
  }

  return (
    <div className="space-y-4">
      {messages.map((m) => {
        const isMine = m.authorRole === viewerRole;
        return (
          <div key={m.id} className={`flex ${isMine ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-md rounded-xl px-4 py-3 ${
                isMine ? "bg-ink text-paper" : "bg-paper-dim border border-line"
              }`}
            >
              <p className={`text-xs mb-1 ${isMine ? "text-paper/60" : "text-ink/50"}`}>
                {isMine ? "You" : m.authorName} &middot; {new Date(m.createdAt).toLocaleString()}
              </p>
              {m.text && <p className="text-sm whitespace-pre-line">{m.text}</p>}
              {m.attachmentUrl && (
                <a href={m.attachmentUrl} target="_blank" rel="noopener noreferrer" className="block mt-2">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={m.attachmentUrl}
                    alt="Attachment"
                    className="rounded-lg max-h-64 border border-black/10"
                  />
                </a>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/message-thread.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
"use client";

import { useState } from "react";

export function PhotoLightbox({ src, alt, className }: { src: string; alt: string; className?: string }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button type="button" onClick={() => setOpen(true)} className="block w-full h-full cursor-zoom-in">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={src} alt={alt} className={className} />
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 bg-ink/90 flex items-center justify-center p-6 cursor-zoom-out"
          onClick={() => setOpen(false)}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={src} alt={alt} className="max-w-full max-h-full rounded-lg object-contain" />
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="absolute top-6 right-6 text-paper text-3xl leading-none"
            aria-label="Close"
          >
            &times;
          </button>
        </div>
      )}
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/photo-lightbox.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import Link from "next/link";
import { logoutAction } from "@/app/actions/auth";
import { NotificationBell } from "@/components/notification-bell";
import { IdleLogout } from "@/components/idle-logout";

export function PortalNav({
  role,
  name,
  links,
}: {
  role: string;
  name: string;
  links: { href: string; label: string }[];
}) {
  return (
    <header className="border-b border-line">
      <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between gap-6">
        <div className="flex items-center gap-8 min-w-0">
          <Link href="/" className="font-display text-lg shrink-0">
            WorldPath
          </Link>
          <nav className="hidden sm:flex items-center gap-5 text-sm overflow-x-auto">
            {links.map((l) => (
              <Link
                key={l.href}
                href={l.href}
                className="text-ink/70 hover:text-ink transition-colors whitespace-nowrap"
              >
                {l.label}
              </Link>
            ))}
          </nav>
        </div>
        <div className="flex items-center gap-3 text-sm shrink-0">
          <NotificationBell />
          <Link href="/account" className="text-ink/60 hover:text-ink transition-colors">
            {name} &middot; <span className="uppercase text-xs tracking-wide">{role}</span>
          </Link>
          <form action={logoutAction}>
            <button className="text-teal hover:underline">Log out</button>
          </form>
        </div>
      </div>
      <IdleLogout />
    </header>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/portal-nav.tsx", $content, $Utf8NoBom)

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
  attachment?: { filename: string; content: Buffer } | null
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
} from "@/types";

const DEFAULT_CHECKLIST: DocumentItem[] = [
  { name: "Passport / national ID", done: false },
  { name: "Academic transcripts", done: false },
  { name: "Personal statement / essay", done: false },
  { name: "Recommendation letters", done: false },
  { name: "English proficiency test (if required)", done: false },
  { name: "Financial / sponsorship documents", done: false },
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
 * record. Messages the account authored are kept for the record Ã¢â‚¬â€ see
 * listNotesForStudent Ã¢â‚¬â€ rather than deleted.
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
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, photoUrl, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      code,
      input.userId,
      input.targetLevel,
      JSON.stringify(input.targetCountries),
      JSON.stringify(DEFAULT_CHECKLIST),
      input.scholarshipInterest ? 1 : 0,
      input.currentEducationLevel ?? "",
      input.schoolName ?? "",
      input.applicationType ?? "standard",
      input.photoUrl ?? null,
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
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, founderName = ?, founderTitle = ?, founderBio = ?, founderPhotoUrl = ?, undergradInfo = ?, mastersInfo = ?, phdInfo = ?, scholarshipsInfo = ?, caretakingInfo = ?
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

'@
[System.IO.File]::WriteAllText("src/lib/repo.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
export function BackArrowIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path
        d="M12.5 4.5L6 10l6.5 5.5"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

'@
[System.IO.File]::WriteAllText("src/components/back-arrow-icon.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { createNotification, getUserById, listAdminUsers } from "@/lib/repo";
import { sendNotificationEmail } from "@/lib/email";
import type { NotificationType } from "@/types";

function absoluteUrl(link?: string): string {
  const appUrl = process.env.APP_URL || "http://localhost:3000";
  if (!link) return appUrl;
  return `${appUrl}${link}`;
}

/**
 * Creates an in-app notification for one user and emails them a copy.
 * The notification is always created; the email is best-effort (a Resend
 * hiccup never blocks the in-app notification or throws back to the caller).
 */
export async function notifyUser(input: {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
}) {
  createNotification(input);
  const user = getUserById(input.userId);
  if (user) {
    await sendNotificationEmail(user.email, input.title, input.body ?? "", absoluteUrl(input.link));
  }
}

/** Notifies every admin at once, in-app and by email - for events any admin should see. */
export async function notifyAllAdmins(input: { type: NotificationType; title: string; body?: string; link?: string }) {
  const admins = listAdminUsers();
  for (const admin of admins) {
    createNotification({ ...input, userId: admin.id });
  }
  const linkUrl = absoluteUrl(input.link);
  await Promise.all(admins.map((admin) => sendNotificationEmail(admin.email, input.title, input.body ?? "", linkUrl)));
}

'@
[System.IO.File]::WriteAllText("src/lib/notify.ts", $content, $Utf8NoBom)

git add -A
git commit -m "Fix garbled characters project-wide; notifications now also send email"
git push

Write-Host 'Done. Files written and pushed.'