# WorldPath Group - notifications, auto-logout, welcome email, and the
# standard-application form-request flow.
#
# This script ALSO fixes a corrupted double byte-order-mark (BOM) that had
# silently built up across most of the project from Windows PowerShell's
# Set-Content -Encoding utf8 (which always adds a BOM) being used across
# many earlier scripts. That's what caused the last deploy to fail with
# 'Unexpected character' errors. This script writes files a different way
# (.NET WriteAllText with BOM explicitly disabled) so this can't happen
# again, regardless of PowerShell version.
#
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
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
        {isBoard ? "Board Â· " : ""}
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
"use client";

import { useActionState } from "react";
import { changePasswordAction, type FormState } from "@/app/actions/account";

const initialState: FormState = {};

export function ChangePasswordForm() {
  const [state, formAction, pending] = useActionState(changePasswordAction, initialState);

  return (
    <form action={formAction} className="space-y-5 max-w-sm">
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Current password</span>
        <input name="currentPassword" type="password" required className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">New password</span>
        <input name="newPassword" type="password" required minLength={8} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Confirm new password</span>
        <input name="confirmPassword" type="password" required minLength={8} className="input" />
      </label>

      {state.error && (
        <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>
      )}
      {state.success && (
        <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>
      )}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Update password"}
      </button>
    </form>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/account/change-password-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/account" | Out-Null
$content = @'
import Link from "next/link";
import { getSession } from "@/lib/auth";
import { logoutAction } from "@/app/actions/auth";
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
                ← Back to dashboard
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

import bcrypt from "bcryptjs";
import { getSession } from "@/lib/auth";
import { getUserById, setUserPassword } from "@/lib/repo";
import { changePasswordSchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

export async function changePasswordAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const session = await getSession();
  if (!session) {
    return { error: "You need to be logged in to do this." };
  }

  const parsed = changePasswordSchema.safeParse({
    currentPassword: String(formData.get("currentPassword") || ""),
    newPassword: String(formData.get("newPassword") || ""),
    confirmPassword: String(formData.get("confirmPassword") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const user = getUserById(session.userId);
  if (!user || !user.passwordHash) {
    return { error: "We couldn't find your account." };
  }

  const valid = await bcrypt.compare(parsed.data.currentPassword, user.passwordHash);
  if (!valid) {
    return { error: "Current password is incorrect." };
  }

  const newHash = await bcrypt.hash(parsed.data.newPassword, 10);
  setUserPassword(user.id, newHash);

  return { success: "Password updated." };
}


'@
[System.IO.File]::WriteAllText("src/app/actions/account.ts", $content, $Utf8NoBom)

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
  createNotification,
} from "@/lib/repo";
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
      createNotification({
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
  notifyAllAdmins,
} from "@/lib/repo";
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

  notifyAllAdmins({
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

  notifyAllAdmins({
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
import { createLead, markLeadHandled, notifyAllAdmins } from "@/lib/repo";
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
  notifyAllAdmins({
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
  createNotification,
} from "@/lib/repo";
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
  createNotification({
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

  createNotification({
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
import { getStudentByUserId, updateStudentDocuments, addNote, createNotification, getStaffById } from "@/lib/repo";
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

function notifyAssignedStaff(
  assignedStaffId: string | null,
  studentId: string,
  input: { type: "message" | "document_uploaded" | "form_requested"; title: string; body: string }
) {
  if (!assignedStaffId) return;
  const staff = getStaffById(assignedStaffId);
  if (!staff?.userId) return;
  createNotification({
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

  notifyAssignedStaff(student.assignedStaffId, student.id, {
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

  notifyAssignedStaff(student.assignedStaffId, student.id, {
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

  createNotification({
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

New-Item -ItemType Directory -Force -Path "src/app/admin/board" | Out-Null
$content = @'
import Link from "next/link";
import { listBoardMembers } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteBoardMemberAction } from "@/app/actions/admin";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AdminBoardPage() {
  const board = listBoardMembers();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Board of Directors</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/board/new" className="btn-primary">
          + Add member
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {board.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No board members yet.</p>}
        {board.map((b) => (
          <div key={b.id} className="p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
              {b.photoUrl ? (
                <PhotoLightbox src={b.photoUrl} alt={b.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full grid place-items-center text-xs text-ink/40">{b.name.charAt(0)}</div>
              )}
            </div>
            <div className="flex-1">
              <p className="font-medium">{b.name}</p>
              <p className="text-sm text-ink/60">{b.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/board/${b.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={b.id} action={deleteBoardMemberAction} confirmLabel={`Remove ${b.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/board/page.tsx", $content, $Utf8NoBom)

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
        <Field label="Description (projects, partnerships â€” shown on the homepage and the Foundation page)">
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
        <Field label="Donate details (bank account / mobile money â€” shown on the Get Involved page)">
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
                    {l.phone ? ` Â· ${l.phone}` : ""}
                  </p>
                  {areas.length > 0 && (
                    <p className="text-sm text-teal mt-2">{areas.join(" Â· ")}</p>
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

New-Item -ItemType Directory -Force -Path "src/app/admin" | Out-Null
$content = @'
import Link from "next/link";
import { listStudents, listStaff, listBoardMembers, listUsers } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import { ArrowRight } from "@/components/arrow-right";

export const dynamic = "force-dynamic";

export default function AdminDashboard() {
  const students = listStudents();
  const staff = listStaff();
  const board = listBoardMembers();
  const users = listUsers();

  const unassigned = students.filter((s) => !s.assignedStaffId).length;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Dashboard</h1>
      <p className="text-ink/60 mb-8">A quick look at WorldPath Group right now.</p>

      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
        <Stat label="Students" value={students.length} href="/admin/students" />
        <Stat label="Unassigned students" value={unassigned} href="/admin/students" accent={unassigned > 0} />
        <Stat label="Staff members" value={staff.length} href="/admin/staff" />
        <Stat label="Board members" value={board.length} href="/admin/board" />
      </div>

      <div className="grid sm:grid-cols-2 gap-8">
        <div>
          <h2 className="font-display text-xl mb-4">Applications by stage</h2>
          <div className="space-y-2">
            {APPLICATION_STATUSES.map((status) => {
              const count = students.filter((s) => s.status === status.value).length;
              return (
                <div key={status.value} className="flex items-center justify-between border-b border-line py-2 text-sm">
                  <span>{status.label}</span>
                  <span className="font-medium">{count}</span>
                </div>
              );
            })}
          </div>
        </div>
        <div>
          <h2 className="font-display text-xl mb-4">Accounts</h2>
          <div className="space-y-2 text-sm">
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Admins</span>
              <span className="font-medium">{users.filter((u) => u.role === "admin").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Staff</span>
              <span className="font-medium">{users.filter((u) => u.role === "staff").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Students</span>
              <span className="font-medium">{users.filter((u) => u.role === "student").length}</span>
            </div>
          </div>
          <Link href="/admin/users" className="inline-block mt-4 text-sm text-teal hover:underline">
            Manage accounts
            <ArrowRight />
          </Link>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value, href, accent }: { label: string; value: number; href: string; accent?: boolean }) {
  return (
    <Link
      href={href}
      className={`block border rounded-xl p-5 hover:border-ink transition-colors ${
        accent ? "border-gold-deep bg-gold/5" : "border-line"
      }`}
    >
      <p className="text-3xl font-display">{value}</p>
      <p className="text-sm text-ink/60 mt-1">{label}</p>
    </Link>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/staff/[id]" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { emailStaffAction, type FormState } from "@/app/actions/admin";

export function EmailStaffForm({ staffId, staffEmail }: { staffId: string; staffEmail: string }) {
  const action = emailStaffAction.bind(null, staffId);
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-4 max-w-lg">
      <p className="text-sm text-ink/60">Sending to {staffEmail}</p>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Subject</span>
        <input name="subject" required className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Message</span>
        <textarea name="body" required rows={6} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Attachment (optional)</span>
        <input
          name="attachment"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf,.doc,.docx"
          className="input"
        />
        <span className="block text-xs text-ink/50 mt-1">Up to 8MB.</span>
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send email"}
      </button>
    </form>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/staff/[id]/email-staff-form.tsx", $content, $Utf8NoBom)

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
            No linked login account yet â€” nothing to email. Create one from the Accounts page.
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

New-Item -ItemType Directory -Force -Path "src/app/admin/staff" | Out-Null
$content = @'
import Link from "next/link";
import { listStaff } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteStaffAction } from "@/app/actions/admin";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AdminStaffPage() {
  const staff = listStaff();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Staff directory</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/staff/new" className="btn-primary">
          + Add staff
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {staff.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No staff members yet.</p>}
        {staff.map((s) => (
          <div key={s.id} className="p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
              {s.photoUrl ? (
                <PhotoLightbox src={s.photoUrl} alt={s.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full grid place-items-center text-xs text-ink/40">{s.name.charAt(0)}</div>
              )}
            </div>
            <div className="flex-1">
              <p className="font-medium">{s.name}</p>
              <p className="text-sm text-ink/60">{s.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/staff/${s.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={s.id} action={deleteStaffAction} confirmLabel={`Remove ${s.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/staff/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/students/[id]" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { emailStudentAction, type FormState } from "@/app/actions/admin";

export function EmailStudentForm({ studentId, studentEmail }: { studentId: string; studentEmail: string }) {
  const action = emailStudentAction.bind(null, studentId);
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-4 max-w-lg">
      <p className="text-sm text-ink/60">Sending to {studentEmail}</p>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Subject</span>
        <input name="subject" required className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Message</span>
        <textarea name="body" required rows={6} className="input" />
      </label>
      <label className="block">
        <span className="block text-sm font-medium mb-1.5">Attachment (optional)</span>
        <input
          name="attachment"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf,.doc,.docx"
          className="input"
        />
        <span className="block text-xs text-ink/50 mt-1">Up to 8MB.</span>
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send email"}
      </button>
    </form>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/admin/students/[id]/email-student-form.tsx", $content, $Utf8NoBom)

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
          value={student.applicationType === "free_shs" ? "Free Â· SHS partnership" : "Standard"}
        />
        <InfoCard label="Targeting" value={`${student.targetLevel} â€” ${targetCountries.join(", ")}`} />
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
                  {doc.done ? "âœ“" : ""}
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
      name: user?.name || "â€”",
      email: user?.email || "â€”",
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
            <span className="text-xs uppercase tracking-wide text-gold-deep font-medium">Free Â· SHS</span>
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
        its login and any linked profile â€” staff and student records included.
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

New-Item -ItemType Directory -Force -Path "src/app/api/uploads/[filename]" | Out-Null
$content = @'
import { NextRequest, NextResponse } from "next/server";
import fs from "node:fs/promises";
import path from "node:path";
import { uploadDir } from "@/lib/uploads";

const CONTENT_TYPES: Record<string, string> = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".pdf": "application/pdf",
};

export async function GET(_request: NextRequest, { params }: { params: Promise<{ filename: string }> }) {
  const { filename } = await params;

  // Guard against path traversal â€” only allow a bare filename.
  if (!filename || filename.includes("/") || filename.includes("..")) {
    return new NextResponse("Not found", { status: 404 });
  }

  const ext = path.extname(filename).toLowerCase();
  const contentType = CONTENT_TYPES[ext];
  if (!contentType) {
    return new NextResponse("Not found", { status: 404 });
  }

  try {
    const filePath = path.join(uploadDir(), filename);
    const data = await fs.readFile(filePath);
    return new NextResponse(new Uint8Array(data), {
      headers: {
        "Content-Type": contentType,
        "Cache-Control": "public, max-age=31536000, immutable",
      },
    });
  } catch {
    return new NextResponse("Not found", { status: 404 });
  }
}


'@
[System.IO.File]::WriteAllText("src/app/api/uploads/[filename]/route.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/blog/[slug]" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { marked } from "marked";
import { getSiteContent, getPostBySlug } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
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
            ← Back to blog
          </Link>

          {tags.length > 0 && (
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mt-6">{tags.join(" · ")}</p>
          )}
          <h1 className="font-display text-3xl sm:text-4xl mt-3 mb-4">{post.title}</h1>
          <p className="text-sm text-ink/50 mb-8">
            {post.authorName}
            {post.publishedAt ? ` · ${new Date(post.publishedAt).toLocaleDateString()}` : ""}
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
                        {p.publishedAt ? new Date(p.publishedAt).toLocaleDateString() : ""} Â· {p.authorName}
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

New-Item -ItemType Directory -Force -Path "src/app/contact" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { submitLeadAction, type FormState } from "@/app/actions/leads";

export function ContactForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(submitLeadAction, {});

  if (state.success) {
    return <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>;
  }

  return (
    <form action={formAction} className="space-y-4">
      <input type="hidden" name="type" value="contact" />
      <input name="name" required placeholder="Your name" className="input" />
      <input name="email" type="email" required placeholder="Email address" className="input" />
      <textarea name="message" required rows={4} placeholder="How can we help?" className="input" />

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send message"}
      </button>
    </form>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/contact/contact-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/contact" | Out-Null
$content = @'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { ContactForm } from "./contact-form";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Contact | ${content.orgName}`,
    description: `Get in touch with ${content.orgName}.`,
  };
}

export default function ContactPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-4xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Contact</p>
          <h1 className="font-display text-4xl mt-4 mb-10">Get in touch</h1>

          <div className="grid sm:grid-cols-2 gap-12">
            <div>
              <h2 className="font-display text-lg mb-3">Reach us directly</h2>
              <div className="space-y-1 text-ink/70">
                {content.contactEmail && <p>{content.contactEmail}</p>}
                {content.contactPhone && <p>{content.contactPhone}</p>}
                {content.address && <p className="whitespace-pre-line">{content.address}</p>}
              </div>
            </div>
            <div>
              <h2 className="font-display text-lg mb-3">Send a message</h2>
              <ContactForm />
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/contact/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/foundation" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `WorldPath Caretaking Foundation | ${content.orgName}`,
    description:
      "The nonprofit organization behind WorldPath Group, supporting education, mentorship, healthcare outreach, and community development across Ghana.",
  };
}

export default function FoundationPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Beyond admissions</p>
          <h1 className="font-display text-4xl mt-4 mb-8">WorldPath Caretaking Foundation</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">
            {content.caretakingInfo ||
 "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities - because a student's wellbeing at home is part of their path to university too."}
          </p>

          <div className="mt-12 pt-8 border-t border-line">
            <Link href="/get-involved" className="btn-primary inline-block">
              See how you can help
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter
        orgName={content.orgName}
        contactEmail={content.contactEmail}
        contactPhone={content.contactPhone}
        address={content.address}
      />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/foundation/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/get-involved" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { LeadForm } from "@/components/lead-form";
import { VolunteerApplicationForm } from "@/components/volunteer-application-form";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Get Involved | ${content.orgName}`,
 description: "Donate, volunteer, or apply - ways to get involved with WorldPath Group.",
  };
}

export default function GetInvolvedPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 pt-16 pb-8 text-center">
          <p className="uppercase tracking-[0.25em] text-xs text-gold-deep font-medium">Get involved</p>
          <h1 className="font-display text-4xl sm:text-5xl mt-5">Three ways to help open a door</h1>
          <p className="mt-6 text-lg text-ink/70 max-w-xl mx-auto">
 Donate, volunteer your time and expertise, or - if you're a student - apply for support.
          </p>
        </section>

        {/* Apply */}
        <section id="apply" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-2">For students</p>
              <h2 className="font-display text-2xl mb-2">Apply for application support</h2>
              <p className="text-paper/75 max-w-md">
                Free through our partnership with Wesley Senior High School, and open to other talented
                students in need across Ghana.
              </p>
            </div>
            <Link href="/register" className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Start your application
            </Link>
          </div>
        </section>

        {/* Donate */}
        <section id="donate" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Donate</p>
          <h2 className="font-display text-3xl mb-6">Fund a student's application</h2>
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <p className="text-ink/70 leading-relaxed whitespace-pre-line">
                {content.donateInfo || "Contact us to arrange a donation."}
              </p>
              <p className="text-sm text-ink/50 mt-4">
                Questions? Email{" "}
                <a href={`mailto:${content.contactEmail}`} className="text-teal hover:underline">
                  {content.contactEmail}
                </a>
                .
              </p>
            </div>
            <div>
              <p className="text-sm font-medium mb-3">Or let us know you're planning to give:</p>
              <LeadForm
                type="donate"
                messagePlaceholder="How would you like to support WorldPath Group?"
                submitLabel="Send"
              />
            </div>
          </div>
        </section>

        {/* Volunteer */}
        <section id="volunteer" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Volunteer</p>
          <h2 className="font-display text-3xl mb-3">Join WorldPath Group as a volunteer</h2>
          <p className="text-ink/70 max-w-2xl mb-8">
            We're always looking for essay reviewers, mock interviewers, and counselors who've been
            through the process themselves.
          </p>
          <div className="max-w-xl">
            <VolunteerApplicationForm />
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/get-involved/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
$content = @'
import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
// Google requires at least 48x48 to reliably show a favicon in search
// results at all (smaller sizes often just fall back to a generic globe
// icon) â€” 128x128 gives good headroom and stays sharp on high-DPI screens.
export const size = { width: 128, height: 128 };
export const contentType = "image/png";

async function logoDataUri(logoUrl: string | null): Promise<string | null> {
  if (!logoUrl || !logoUrl.startsWith("/api/uploads/")) return null;
  try {
    const filename = logoUrl.replace("/api/uploads/", "");
    const filePath = path.join(uploadDir(), filename);
    const buffer = await fs.readFile(filePath);
    const ext = path.extname(filename).slice(1);
    const mime = ext === "jpg" ? "jpeg" : ext;
    return `data:image/${mime};base64,${buffer.toString("base64")}`;
  } catch {
    return null;
  }
}

export default async function Icon() {
  const content = getSiteContent();
  const logo = await logoDataUri(content.logoUrl);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: logo ? "transparent" : "#0a2e3d",
          borderRadius: "50%",
        }}
      >
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} width={128} height={128} style={{ borderRadius: "50%", objectFit: "cover" }} />
        ) : (
          <span style={{ color: "#faf8f4", fontSize: 72 }}>W</span>
        )}
      </div>
    ),
    { ...size }
  );
}


'@
[System.IO.File]::WriteAllText("src/app/icon.tsx", $content, $Utf8NoBom)

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
                        {s.destinationCountry} Â· {s.targetLevel}
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

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
$content = @'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.APP_URL || "http://localhost:3000"),
  title: {
    default: "WorldPath Group | University & Scholarship Applications",
    template: "%s | WorldPath Group",
  },
  description:
    "WorldPath Group helps talented Ghanaian students apply to universities and scholarships in the USA, Canada, UK, Germany, and Asia.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <head>
        <meta charSet="utf-8" />
      </head>
      <body className="min-h-full flex flex-col bg-paper text-ink">{children}</body>
    </html>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/layout.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
$content = @'
import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const alt = "WorldPath Group";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

async function logoDataUri(logoUrl: string | null): Promise<string | null> {
  if (!logoUrl || !logoUrl.startsWith("/api/uploads/")) return null;
  try {
    const filename = logoUrl.replace("/api/uploads/", "");
    const filePath = path.join(uploadDir(), filename);
    const buffer = await fs.readFile(filePath);
    const ext = path.extname(filename).slice(1);
    const mime = ext === "jpg" ? "jpeg" : ext;
    return `data:image/${mime};base64,${buffer.toString("base64")}`;
  } catch {
    return null;
  }
}

export default async function Image() {
  const content = getSiteContent();
  const logo = await logoDataUri(content.logoUrl);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: "#082029",
          color: "#faf8f4",
        }}
      >
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={logo}
            width={180}
            height={180}
            style={{ borderRadius: "50%", marginBottom: 36, objectFit: "cover" }}
          />
        ) : (
          <div
            style={{
              width: 150,
              height: 150,
              borderRadius: "50%",
              background: "#0f6e8c",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 68,
              marginBottom: 36,
            }}
          >
            W
          </div>
        )}
        <div style={{ fontSize: 58, fontWeight: 600 }}>{content.orgName}</div>
        <div style={{ fontSize: 28, color: "#faf8f4b3", marginTop: 18, maxWidth: 820, textAlign: "center" }}>
          {content.tagline}
        </div>
      </div>
    ),
    { ...size }
  );
}


'@
[System.IO.File]::WriteAllText("src/app/opengraph-image.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
$content = @'
import Link from "next/link";
import { getSiteContent, listImpactStories } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PathRoute } from "@/components/path-route";
import { ArrowRight } from "@/components/arrow-right";
import { CheckIcon } from "@/components/check-icon";
import { JourneyPath } from "@/components/journey-path";

export const dynamic = "force-dynamic";

const CREDIBILITY_POINTS = [
  "One-on-one mentoring",
  "Scholarship-focused applications",
  "Student-centered support",
  "International study pathways",
];

const WHAT_STUDENTS_RECEIVE = [
  {
    title: "A tailored university shortlist",
    body: "Schools matched to your grades, goals, and budget - not a generic list.",
  },
  {
    title: "Personal statement & essay guidance",
    body: "One-on-one feedback to help your application sound like you, at your best.",
  },
  {
    title: "Scholarship & financial-aid search",
    body: "We help you find and apply for merit-based and need-based aid, especially in the US.",
  },
  {
    title: "Document review & tracking",
    body: "Your own portal to track every document and every stage - always up to date.",
  },
  {
    title: "Interview preparation",
    body: "Practice and coaching where an admissions or scholarship interview is required.",
  },
];

const HOW_IT_WORKS = [
  { title: "Apply online", body: "Create your account and tell us about your goals." },
  { title: "Meet an advisor", body: "We match you with a counselor to plan your path." },
  { title: "Prepare documents", body: "Essays, transcripts, and recommendations - reviewed together." },
  { title: "Submit applications", body: "We help you apply to universities and scholarships on time." },
  { title: "Track results", body: "Follow every stage from your own student portal." },
];

export default function HomePage() {
  const content = getSiteContent();
  const testimonial = listImpactStories().find((s) => s.featured === 1);

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        {/* Hero - full-bleed navy, IvyWise-style */}
        <section
          className="relative bg-navy text-paper overflow-hidden bg-cover bg-center"
          style={content.heroImageUrl ? { backgroundImage: `url(${content.heroImageUrl})` } : undefined}
        >
          {content.heroImageUrl && <div className="absolute inset-0 bg-navy/75" />}
          <div
            className="absolute inset-0 opacity-40"
            style={{
              background:
                "radial-gradient(ellipse 90% 60% at 50% -10%, rgba(15,110,140,0.55), transparent 60%)",
            }}
          />
          <div className="relative mx-auto max-w-5xl px-6 pt-24 pb-20 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">
              {content.orgName}
            </p>
            <h1 className="font-display text-4xl sm:text-6xl leading-[1.08] mt-5">
              Talent should decide who gets in.
              <br className="hidden sm:block" /> Not a bank balance.
            </h1>
            <p className="mt-6 text-lg text-paper/75 max-w-xl mx-auto">{content.tagline}</p>
            <div className="mt-9 flex flex-wrap justify-center gap-4">
              <Link
                href="/register"
                className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors"
              >
                Get application support
              </Link>
              <Link
                href="/about"
                className="rounded-full border border-paper/30 px-7 py-3 hover:border-paper/70 transition-colors"
              >
                Meet the team
              </Link>
            </div>
            <div className="mt-4">
              <PathRoute />
            </div>
          </div>
        </section>

        {/* Credibility strip - what we offer, not raw headcounts */}
        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-6 text-center">
            {CREDIBILITY_POINTS.map((point) => (
              <div key={point} className="flex flex-col items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-gold-deep" />
                <p className="text-sm font-medium">{point}</p>
              </div>
            ))}
          </div>
          <div className="text-center pb-8">
            <Link href="/impact" className="text-sm text-teal hover:underline">
              See our impact & student stories
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* What students receive */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Our services</p>
          <h2 className="font-display text-3xl mb-10">What students receive</h2>
          <div className="grid sm:grid-cols-2 gap-x-10 gap-y-8">
            {WHAT_STUDENTS_RECEIVE.map((item) => (
              <div key={item.title} className="flex gap-4">
                <span className="w-6 h-6 rounded-full bg-teal/10 text-teal grid place-items-center shrink-0 mt-0.5">
                  <CheckIcon />
                </span>
                <div>
                  <h3 className="font-medium mb-1">{item.title}</h3>
                  <p className="text-sm text-ink/70 leading-relaxed">{item.body}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">The process</p>
          <h2 className="font-display text-3xl mb-10">How it works</h2>
          <JourneyPath steps={HOW_IT_WORKS} />
        </section>

        {/* Mission */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Mission</p>
              <h2 className="font-display text-2xl mb-3">Why we exist</h2>
              <p className="text-ink/80 leading-relaxed">{content.mission}</p>
            </div>
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Vision</p>
              <h2 className="font-display text-2xl mb-3">Where we're headed</h2>
              <p className="text-ink/80 leading-relaxed">{content.vision}</p>
            </div>
          </div>
        </section>

        {/* Founder */}
        {content.founderName && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-6 text-center sm:text-left">
              Leadership
            </p>
            <div className="flex flex-col sm:flex-row items-center sm:items-start gap-8 text-center sm:text-left">
              <div className="w-32 h-32 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
                {content.founderPhotoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={content.founderPhotoUrl} alt={content.founderName} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full grid place-items-center text-3xl text-ink/30 font-display">
                    {content.founderName.charAt(0)}
                  </div>
                )}
              </div>
              <div>
                <h2 className="font-display text-2xl mb-1">{content.founderName}</h2>
                <p className="text-teal text-sm font-medium mb-4">{content.founderTitle}</p>
                <p className="text-ink/80 leading-relaxed max-w-xl">{content.founderBio}</p>
              </div>
            </div>
          </section>
        )}

        {/* Testimonial - only shown once a real, permitted story is marked featured in admin */}
        {testimonial && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <div className="rounded-2xl border border-gold-deep/30 bg-gold/5 px-8 py-10 sm:px-12 text-center">
              <p className="font-display text-2xl sm:text-3xl leading-snug text-ink mb-6">
                &ldquo;{testimonial.story}&rdquo;
              </p>
              <p className="text-sm font-medium">{testimonial.studentName}</p>
              <p className="text-xs text-ink/50 uppercase tracking-wide mt-1">
                {testimonial.destinationCountry}
              </p>
            </div>
          </section>
        )}

        {/* Caretaking foundation - short summary, full story lives on its own page */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14">
            <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-3">
              Beyond admissions
            </p>
            <h2 className="font-display text-2xl mb-3">About the Foundation</h2>
            <p className="text-paper/80 max-w-2xl leading-relaxed mb-6">
              WorldPath Caretaking Foundation is the nonprofit organization behind WorldPath Group,
              supporting education, mentorship, healthcare outreach, and community development across
              Ghana.
            </p>
            <Link
              href="/foundation"
              className="text-sm text-paper underline hover:text-teal transition-colors"
            >
              Learn more about the Foundation
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* Blog teaser */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="flex items-center justify-between mb-3">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">From the blog</p>
            <Link href="/blog" className="text-sm text-teal hover:underline">
              All posts
              <ArrowRight />
            </Link>
          </div>
          <h2 className="font-display text-2xl mb-3">Guides for applying abroad</h2>
          <p className="text-ink/70 max-w-2xl">
            Scholarship tips, application walkthroughs, and stories from students on their way abroad.
          </p>
        </section>

        {/* Free partnership note + CTA */}
        <section className="mx-auto max-w-6xl px-6 py-16">
          <div className="grid sm:grid-cols-2 gap-10 items-center">
            <div>
              <h2 className="font-display text-2xl mb-3">Free through Wesley Senior High School</h2>
              <p className="text-ink/80 leading-relaxed">
                Through our partnership with Wesley Senior High School, application assistance is
                provided free of charge to eligible students.
              </p>
            </div>
            <div className="sm:text-right">
              <Link href="/register/free" className="btn-primary inline-block">
                Apply for WorldPath guidance
              </Link>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/programs/masters" | Out-Null
$content = @'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Master's Applications | ${content.orgName}`,
    description: "Application support for master's degrees abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function MastersPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Master's"
      title="Master's applications"
      body={content.mastersInfo}
 fallback="We support Ghanaian graduates applying for master's programs abroad - from selecting programs aligned with your career goals to strengthening your statement of purpose and finding funding."
    />
  );
}


'@
[System.IO.File]::WriteAllText("src/app/programs/masters/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/programs/phd" | Out-Null
$content = @'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `PhD Applications | ${content.orgName}`,
    description: "Application support for PhD programs abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function PhdPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="PhD"
      title="PhD applications"
      body={content.phdInfo}
 fallback="We support Ghanaian students pursuing doctoral study abroad - from identifying the right advisors and programs to preparing research proposals and securing funding."
    />
  );
}


'@
[System.IO.File]::WriteAllText("src/app/programs/phd/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/programs/undergraduate" | Out-Null
$content = @'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Undergraduate Applications | ${content.orgName}`,
    description: "Application support for undergraduate study abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function UndergraduatePage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Undergraduate"
      title="Undergraduate applications"
      body={content.undergradInfo}
 fallback="We help Ghanaian students build a competitive undergraduate application - from choosing the right universities to writing standout essays and finding scholarships to make it affordable."
    />
  );
}


'@
[System.IO.File]::WriteAllText("src/app/programs/undergraduate/page.tsx", $content, $Utf8NoBom)

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

import { useActionState, useRef, startTransition } from "react";
import Link from "next/link";
import { registerAction, type FormState } from "@/app/actions/auth";
import { TARGET_LEVELS, TARGET_COUNTRIES, CURRENT_EDUCATION_LEVELS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";
import { ArrowRight } from "@/components/arrow-right";

const initialState: FormState = {};

export default function RegisterPage() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);

  // React resets uncontrolled form fields the moment a <form action={...}>
  // submits â€” including on a failed submission. On a form this long,
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

          <Field label="What are you applying for?">
            <select name="targetLevel" className="input" defaultValue="undergrad">
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


'@
[System.IO.File]::WriteAllText("src/app/register/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/scholarships" | Out-Null
$content = @'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Scholarships | ${content.orgName}`,
    description: "Scholarship and financial aid support for Ghanaian students applying to study abroad.",
  };
}

export default function ScholarshipsPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Funding"
      title="Scholarships & financial aid"
      body={content.scholarshipsInfo}
 fallback="We help you find and apply for merit-based and need-based scholarships and financial aid - especially at US universities, where most funding decisions are made as part of the admissions process itself."
    />
  );
}


'@
[System.IO.File]::WriteAllText("src/app/scholarships/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
$content = @'
import type { MetadataRoute } from "next";
import { listPublishedPosts } from "@/lib/repo";

export const dynamic = "force-dynamic";

function siteUrl(): string {
  return (process.env.APP_URL || "http://localhost:3000").replace(/\/$/, "");
}

export default function sitemap(): MetadataRoute.Sitemap {
  const base = siteUrl();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${base}/`, changeFrequency: "weekly", priority: 1 },
    { url: `${base}/about`, changeFrequency: "monthly", priority: 0.6 },
    { url: `${base}/foundation`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${base}/impact`, changeFrequency: "weekly", priority: 0.8 },
    { url: `${base}/get-involved`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/blog`, changeFrequency: "daily", priority: 0.8 },
    { url: `${base}/register`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${base}/register/free`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${base}/programs/undergraduate`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/programs/masters`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/programs/phd`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/scholarships`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/contact`, changeFrequency: "monthly", priority: 0.5 },
  ];

  const postRoutes: MetadataRoute.Sitemap = listPublishedPosts().map((post) => ({
    url: `${base}/blog/${post.slug}`,
    lastModified: post.updatedAt,
    changeFrequency: "monthly",
    priority: 0.6,
  }));

  return [...staticRoutes, ...postRoutes];
}


'@
[System.IO.File]::WriteAllText("src/app/sitemap.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/staff" | Out-Null
$content = @'
import Link from "next/link";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, listStudentsByStaff, getUserById } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";

export const dynamic = "force-dynamic";

export default async function StaffHomePage() {
  const session = await getSession();
  const staff = session ? getStaffByUserId(session.userId) : undefined;
  const students = staff ? listStudentsByStaff(staff.id) : [];

  const statusLabel = (value: string) => APPLICATION_STATUSES.find((s) => s.value === value)?.label ?? value;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">My students</h1>
      <p className="text-ink/60 mb-8">Students currently assigned to you.</p>

      {!staff && (
        <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
          No staff profile is linked to your account yet. Ask an admin to link one.
        </p>
      )}

      {staff && students.length === 0 && (
        <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
          No students are assigned to you yet.
        </p>
      )}

      {staff && students.length > 0 && (
        <div className="divide-y divide-line border border-line rounded-xl">
          {students.map((s) => {
            const user = getUserById(s.userId);
            return (
              <Link
                key={s.id}
                href={`/staff/students/${s.id}`}
                className="p-4 flex items-center gap-4 hover:bg-paper-dim transition-colors"
              >
                <div className="w-10 h-10 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
                  {s.photoUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={s.photoUrl} alt={user?.name || ""} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full grid place-items-center text-xs text-ink/40">
                      {user?.name?.charAt(0) ?? "?"}
                    </div>
                  )}
                </div>
                <div className="flex-1">
                  <p className="font-medium">{user?.name}</p>
                  <p className="text-xs text-ink/50 font-mono">{s.code}</p>
                </div>
                <span className="text-xs uppercase tracking-wide text-gold-deep">{statusLabel(s.status)}</span>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/staff/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
$content = @'
"use client";

import { staffToggleDocumentAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

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
                {doc.done ? "âœ“" : ""}
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

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, getStudentById, getUserById, listNotesForStudent } from "@/lib/repo";
import { StatusSelect } from "./status-select";
import { DocumentChecklist } from "./document-checklist";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { PhotoLightbox } from "@/components/photo-lightbox";
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
        </div>
      </div>

      <div className="grid sm:grid-cols-2 gap-8 mb-10">
        <div>
          <h2 className="text-sm font-medium mb-2">Application status</h2>
          <StatusSelect studentId={student.id} status={student.status} />
        </div>
        <div>
          <h2 className="text-sm font-medium mb-2">Targeting</h2>
          <p className="text-sm text-ink/70 capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <DocumentChecklist studentId={student.id} documents={documents} />
      </div>

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

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
"use client";

import { useRef, useState, useTransition } from "react";
import { studentUploadDocumentAction } from "@/app/actions/student";
import type { DocumentItem } from "@/types";

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
            {doc.done ? "âœ“" : ""}
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

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";
import { DocumentUploadRow } from "./document-upload-row";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { studentAddNoteAction } from "@/app/actions/student";
import { RequestFormButton } from "./request-form-button";

export const dynamic = "force-dynamic";

export default async function StudentHomePage() {
  const session = await getSession();
  const student = session ? getStudentByUserId(session.userId) : undefined;

  if (!student) {
    return <p className="text-ink/60">We couldn't find your application record. Please contact WorldPath Group.</p>;
  }

  const staff = student.assignedStaffId ? getStaffById(student.assignedStaffId) : undefined;
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const completedDocs = documents.filter((d) => d.done).length;

  return (
    <div>
      <div className="flex items-center gap-4 mb-3">
        <div className="w-14 h-14 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={student.photoUrl} alt={session?.name || ""} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-ink/40">{session?.name?.charAt(0) ?? "?"}</div>
          )}
        </div>
        <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block">
          {student.code}
        </p>
      </div>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
 {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet - one will be soon."}
      </p>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Application status</p>
          <p className="font-display text-xl text-gold-deep">{statusLabel}</p>
        </div>
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Targeting</p>
          <p className="capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      {student.applicationType === "standard" && student.assignedStaffId && (
        <div className="border border-gold-deep/30 bg-gold/5 rounded-xl p-5 mb-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <p className="font-medium mb-1">Need your application form?</p>
            <p className="text-sm text-ink/60">
              Standard applications start with a request to your counselor rather than a default
              checklist. They'll reply in your message thread with the form attached.
            </p>
          </div>
          <RequestFormButton />
        </div>
      )}

      <div className="mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display text-xl">Document checklist</h2>
          <span className="text-sm text-ink/50">
            {completedDocs}/{documents.length} complete
          </span>
        </div>
        <p className="text-xs text-ink/50 mb-3">
          Upload a photo or PDF of each document. Uploading automatically marks it complete.
        </p>
        <ul className="space-y-2">
          {documents.map((doc, index) => (
            <DocumentUploadRow key={doc.name} doc={doc} index={index} />
          ))}
        </ul>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Messages with your counselor</h2>
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
            viewerRole="student"
          />
        </div>
        <MessageForm action={studentAddNoteAction} placeholder="Send a message to your counselor..." />
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/student/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
export function ArrowRight({ className = "inline-block w-3.5 h-3.5 ml-1 -mb-0.5" }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
      <path
        d="M3 8h10M9 4l4 4-4 4"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/arrow-right.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
export function CheckIcon({ className = "w-3.5 h-3.5" }: { className?: string }) {
  return (
    <svg viewBox="0 0 20 20" fill="none" className={className} aria-hidden="true">
      <path
        d="M4 10.5L8 14.5L16 6"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/check-icon.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
interface JourneyStep {
  title: string;
  body: string;
}

export function JourneyPath({ steps }: { steps: JourneyStep[] }) {
  return (
    <div className="w-full overflow-x-auto">
      <div className="relative min-w-[900px] pt-6 pb-2">
        <svg
          viewBox="0 0 1000 60"
          preserveAspectRatio="none"
          className="absolute left-0 right-0 top-10 w-full h-16 pointer-events-none"
          aria-hidden="true"
        >
          <path
            d="M20,30 C 120,-10 130,70 230,30 C 330,-10 340,70 440,30 C 540,-10 550,70 650,30 C 750,-10 760,70 860,30 C 900,10 940,30 980,30"
            fill="none"
            stroke="var(--color-teal)"
            strokeOpacity="0.5"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
        </svg>
        <div className="relative flex justify-between">
          {steps.map((step, i) => (
            <div
              key={step.title}
              className={`flex flex-col items-center text-center w-[180px] ${i % 2 === 1 ? "mt-10" : ""}`}
            >
              <span className="w-4 h-4 rounded-full bg-gold-deep border-2 border-paper" />
              <p className="font-display text-base mt-3 mb-1">{step.title}</p>
              <p className="text-xs text-ink/60 leading-relaxed">{step.body}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/journey-path.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
"use client";

import { useActionState, useRef, useState } from "react";
import type { FormState } from "@/app/actions/auth";

export function MessageForm({
  action,
  placeholder,
}: {
  action: (prevState: FormState, formData: FormData) => Promise<FormState>;
  placeholder: string;
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});
  const [preview, setPreview] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      action={async (formData) => {
        await formAction(formData);
        formRef.current?.reset();
        setPreview(null);
      }}
      className="space-y-3"
    >
      <textarea name="text" rows={2} placeholder={placeholder} className="input" />

      {preview && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={preview} alt="Attachment preview" className="h-20 rounded-lg border border-line" />
      )}

      <div className="flex items-center justify-between gap-3">
        <label className="text-sm text-teal hover:underline cursor-pointer">
          {preview ? "Change picture" : "+ Attach a picture"}
          <input
            ref={fileRef}
            type="file"
            name="image"
            accept="image/jpeg,image/png,image/webp,image/gif"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (!file) return;
              const reader = new FileReader();
              reader.onload = () => setPreview(reader.result as string);
              reader.readAsDataURL(file);
            }}
          />
        </label>
        <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
          {pending ? "Sending..." : "Send"}
        </button>
      </div>

      {state.error && <p className="text-sm text-red-700">{state.error}</p>}
    </form>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/message-form.tsx", $content, $Utf8NoBom)

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
                {isMine ? "You" : m.authorName} Â· {new Date(m.createdAt).toLocaleString()}
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
            Ã—
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
"use client";

import { useRef, useState } from "react";

export function PhotoUploadField({
  existingUrl,
  name = "photo",
  hiddenFieldName = "existingPhotoUrl",
  shape = "circle",
}: {
  existingUrl?: string | null;
  name?: string;
  hiddenFieldName?: string;
  shape?: "circle" | "rect";
}) {
  const [preview, setPreview] = useState<string | null>(existingUrl || null);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  function handleFiles(files: FileList | null) {
    const file = files?.[0];
    if (!file) return;
    if (inputRef.current) {
      const dt = new DataTransfer();
      dt.items.add(file);
      inputRef.current.files = dt.files;
    }
    const reader = new FileReader();
    reader.onload = () => setPreview(reader.result as string);
    reader.readAsDataURL(file);
  }

  return (
    <div>
      <input type="hidden" name={hiddenFieldName} value={existingUrl ?? ""} />
      <div
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          handleFiles(e.dataTransfer.files);
        }}
        onClick={() => inputRef.current?.click()}
        className={`flex items-center gap-4 border-2 border-dashed rounded-xl p-4 cursor-pointer transition-colors ${
          dragging ? "border-teal bg-teal/5" : "border-line hover:border-teal/60"
        }`}
      >
        <div
          className={`bg-paper-dim border border-line grid place-items-center overflow-hidden shrink-0 ${
            shape === "circle" ? "w-24 h-24 rounded-full" : "w-32 h-20 rounded-lg"
          }`}
        >
          {preview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={preview} alt="Preview" className="w-full h-full object-cover" />
          ) : (
            <span className="text-xs text-ink/40">No photo</span>
          )}
        </div>
        <div className="text-sm">
          <p className="text-ink">
            <span className="text-teal">Click to upload</span> or drag and drop
          </p>
 <p className="text-ink/50 text-xs mt-0.5">JPG, PNG, WEBP, or GIF - up to 5MB</p>
        </div>
      </div>
      <input
        ref={inputRef}
        type="file"
        name={name}
        accept="image/jpeg,image/png,image/webp,image/gif"
        onChange={(e) => handleFiles(e.target.files)}
        className="hidden"
      />
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/photo-upload-field.tsx", $content, $Utf8NoBom)

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
            {name} · <span className="uppercase text-xs tracking-wide">{role}</span>
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

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export function ProgramPageLayout({
  eyebrow,
  title,
  body,
  fallback,
  applyHref = "/register",
}: {
  eyebrow: string;
  title: string;
  body: string;
  fallback: string;
  applyHref?: string;
}) {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">{eyebrow}</p>
          <h1 className="font-display text-4xl mt-4 mb-6">{title}</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">{body || fallback}</p>
        </section>

        <section className="mx-auto max-w-3xl px-6 pb-20">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-xl mb-2">Ready to get started?</h2>
              <p className="text-paper/75">We'll match you with a counselor to guide your application.</p>
            </div>
            <Link href={applyHref} className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Get application support
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/program-page-layout.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import Link from "next/link";

export function SiteFooter({
  orgName,
  contactEmail,
  contactPhone,
  address,
}: {
  orgName: string;
  contactEmail: string;
  contactPhone?: string;
  address: string;
}) {
  return (
    <footer className="border-t border-line mt-24">
      <div className="mx-auto max-w-6xl px-6 py-14 grid sm:grid-cols-4 gap-10 text-sm">
        <div className="sm:col-span-1">
          <p className="font-display text-base mb-2">{orgName}</p>
          <p className="text-ink/60 leading-relaxed">
            A project of{" "}
            <Link href="/foundation" className="hover:text-teal transition-colors underline">
              WorldPath Caretaking Foundation
            </Link>
            .
          </p>
        </div>

        <FooterColumn
          title="Programs"
          links={[
            { href: "/programs/undergraduate", label: "Undergraduate" },
            { href: "/programs/masters", label: "Master's" },
            { href: "/programs/phd", label: "PhD" },
            { href: "/scholarships", label: "Scholarships" },
          ]}
        />

        <FooterColumn
          title="Organization"
          links={[
            { href: "/about", label: "About WorldPath" },
            { href: "/impact", label: "Impact" },
            { href: "/blog", label: "Blog" },
            { href: "/get-involved", label: "Get Involved" },
          ]}
        />

        <div>
          <p className="font-medium mb-3">Contact</p>
          <div className="space-y-1 text-ink/60">
            {contactEmail && <p>{contactEmail}</p>}
            {contactPhone && <p>{contactPhone}</p>}
            {address && <p className="whitespace-pre-line">{address}</p>}
          </div>
          <Link href="/contact" className="inline-block mt-2 text-teal hover:underline">
            Contact page
          </Link>
        </div>
      </div>
      <div className="border-t border-line">
        <p className="mx-auto max-w-6xl px-6 py-5 text-xs text-ink/50">
          &copy; {new Date().getFullYear()} {orgName}. All rights reserved.
        </p>
      </div>
    </footer>
  );
}

function FooterColumn({ title, links }: { title: string; links: { href: string; label: string }[] }) {
  return (
    <div>
      <p className="font-medium mb-3">{title}</p>
      <ul className="space-y-1.5">
        {links.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="text-ink/60 hover:text-teal transition-colors">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/site-footer.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import Link from "next/link";

export function SiteHeader({ orgName, logoUrl }: { orgName: string; logoUrl?: string | null }) {
  return (
    <header className="border-b border-line bg-paper/95 backdrop-blur sticky top-0 z-40">
      <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 group">
          {logoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logoUrl} alt={orgName} className="w-8 h-8 rounded-full object-cover" />
          ) : (
            <span className="w-8 h-8 rounded-full bg-ink text-paper grid place-items-center font-display text-sm">
              W
            </span>
          )}
          <span className="font-display text-lg tracking-tight">{orgName}</span>
        </Link>
        <nav className="flex items-center gap-5 sm:gap-6 text-sm">
          <Link href="/about" className="hover:text-gold-deep transition-colors hidden md:inline">
            About &amp; Team
          </Link>
          <Link href="/impact" className="hover:text-gold-deep transition-colors hidden sm:inline">
            Impact
          </Link>
          <Link href="/blog" className="hover:text-gold-deep transition-colors hidden sm:inline">
            Blog
          </Link>
          <Link href="/get-involved" className="hover:text-gold-deep transition-colors hidden md:inline">
            Get Involved
          </Link>
          <Link href="/login" className="hover:text-gold-deep transition-colors">
            Log in
          </Link>
          <Link
            href="/register"
            className="rounded-full bg-ink text-paper px-4 py-2 hover:bg-teal transition-colors"
          >
            Apply now
          </Link>
        </nav>
      </div>
    </header>
  );
}


'@
[System.IO.File]::WriteAllText("src/components/site-header.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { submitLeadAction, type FormState } from "@/app/actions/leads";
import { VOLUNTEER_AREAS } from "@/types";

export function VolunteerApplicationForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(submitLeadAction, {});

  if (state.success) {
    return <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>;
  }

  return (
    <form action={formAction} className="space-y-5">
      <input type="hidden" name="type" value="volunteer" />

      <div className="grid sm:grid-cols-2 gap-4">
        <Field label="Your name">
          <input name="name" required placeholder="Full name" className="input" />
        </Field>
        <Field label="Email address">
          <input name="email" type="email" required placeholder="you@example.com" className="input" />
        </Field>
      </div>

      <Field label="Phone (optional)">
        <input name="phone" placeholder="e.g. 024 000 0000" className="input" />
      </Field>

      <Field label="What would you like to help with? (choose all that apply)">
        <div className="grid sm:grid-cols-2 gap-2">
          {VOLUNTEER_AREAS.map((area) => (
            <label key={area} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
              <input type="checkbox" name="areasOfInterest" value={area} className="accent-teal" />
              {area}
            </label>
          ))}
        </div>
      </Field>

      <Field label="Your availability (optional)">
        <input name="availability" placeholder="e.g. Weekday evenings, 2-3 hours/week" className="input" />
      </Field>

      <Field label="Anything else you'd like us to know? (optional)">
        <textarea name="message" rows={3} placeholder="Your background, motivation, or questions..." className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Submitting..." : "Submit application"}
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
[System.IO.File]::WriteAllText("src/components/volunteer-application-form.tsx", $content, $Utf8NoBom)

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
  ];
  for (const sql of alters) {
    try {
      db.exec(sql);
    } catch {
      // Column already exists â€” fine.
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
 * record. Messages the account authored are kept for the record â€” see
 * listNotesForStudent â€” rather than deleted.
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

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import fs from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";

// Uploaded files are stored under data/uploads (NOT /public). Next.js's
// production server snapshots the contents of /public at build time, so
// files written there while the server is already running wouldn't be
// served until a restart. Serving them instead through the dynamic route
// handler at /api/uploads/[filename] reads the file from disk on every
// request, so newly uploaded files show up immediately.

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(process.cwd(), "data", "uploads");
const MAX_BYTES = 5 * 1024 * 1024; // 5MB

const IMAGE_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
};

const DOCUMENT_TYPES: Record<string, string> = {
  ...IMAGE_TYPES,
  "application/pdf": "pdf",
};

export class UploadError extends Error {}

export function uploadDir(): string {
  return UPLOAD_DIR;
}

async function saveFile(file: File, allowedTypes: Record<string, string>, kindLabel: string): Promise<string> {
  if (file.size === 0) {
    throw new UploadError("No file was selected.");
  }
  if (file.size > MAX_BYTES) {
    throw new UploadError(`File must be smaller than 5MB.`);
  }
  const ext = allowedTypes[file.type];
  if (!ext) {
    throw new UploadError(`Please upload ${kindLabel}.`);
  }

  await fs.mkdir(UPLOAD_DIR, { recursive: true });

  const filename = `${randomUUID()}.${ext}`;
  const buffer = Buffer.from(await file.arrayBuffer());
  await fs.writeFile(path.join(UPLOAD_DIR, filename), buffer);

  return `/api/uploads/${filename}`;
}

/**
 * Saves an uploaded image File to the uploads directory and returns its
 * public URL path (e.g. "/api/uploads/xxxx.jpg"). Throws UploadError on
 * invalid input.
 */
export async function saveUploadedImage(file: File): Promise<string> {
  return saveFile(file, IMAGE_TYPES, "a JPG, PNG, WEBP, or GIF image");
}

/**
 * Saves an uploaded application document (a photo of a document, or a PDF).
 * Used for student document-checklist uploads.
 */
export async function saveUploadedDocument(file: File): Promise<string> {
  return saveFile(file, DOCUMENT_TYPES, "a JPG, PNG, WEBP, GIF, or PDF file");
}

/** Deletes a previously uploaded file given its public URL path, if it's one of ours. */
export async function deleteUploadedImage(url: string | null | undefined): Promise<void> {
  if (!url || !url.startsWith("/api/uploads/")) return;
  const filename = url.replace("/api/uploads/", "");
  if (!filename || filename.includes("/") || filename.includes("..")) return;
  try {
    await fs.unlink(path.join(UPLOAD_DIR, filename));
  } catch {
    // File may already be gone — safe to ignore.
  }
}

'@
[System.IO.File]::WriteAllText("src/lib/uploads.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
  scholarshipInterest: z.boolean(),
  currentEducationLevel: z.enum(["shs_graduate", "tertiary", "graduate", "other"]),
});

export const freeRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  schoolName: z.string().min(2, "Enter your school's name"),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
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


'@
[System.IO.File]::WriteAllText("src/lib/validators.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src" | Out-Null
$content = @'
import { NextRequest, NextResponse } from "next/server";
import { jwtVerify } from "jose";

const SESSION_COOKIE = "wpg_session";

function getSecret(): Uint8Array {
  return new TextEncoder().encode(process.env.JWT_SECRET || "");
}

async function readRole(request: NextRequest): Promise<string | null> {
  const token = request.cookies.get(SESSION_COOKIE)?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, getSecret());
    return (payload.role as string) ?? null;
  } catch {
    return null;
  }
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const role = await readRole(request);

  // /account is shared across all roles — just needs any authenticated session.
  if (pathname.startsWith("/account")) {
    if (!role) {
      const loginUrl = new URL("/login", request.url);
      loginUrl.searchParams.set("next", pathname);
      return NextResponse.redirect(loginUrl);
    }
    return NextResponse.next();
  }

  const requiredRole = pathname.startsWith("/admin")
    ? "admin"
    : pathname.startsWith("/staff")
    ? "staff"
    : pathname.startsWith("/student")
    ? "student"
    : null;

  if (!requiredRole) return NextResponse.next();

  if (!role) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("next", pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (role !== requiredRole) {
    // Signed in, but wrong portal for their role — send them to their own portal.
    return NextResponse.redirect(new URL(`/${role}`, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/staff/:path*", "/student/:path*", "/account/:path*"],
};


'@
[System.IO.File]::WriteAllText("src/proxy.ts", $content, $Utf8NoBom)

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

'@
[System.IO.File]::WriteAllText("src/types/index.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { listNotifications, countUnreadNotifications, markNotificationRead, markAllNotificationsRead } from "@/lib/repo";

export async function getNotificationsAction() {
  const session = await getSession();
  if (!session) return { notifications: [], unreadCount: 0 };
  return {
    notifications: listNotifications(session.userId),
    unreadCount: countUnreadNotifications(session.userId),
  };
}

export async function markNotificationReadAction(id: string) {
  const session = await getSession();
  if (!session) return;
  markNotificationRead(id, session.userId);
  revalidatePath(`/${session.role}`);
}

export async function markAllNotificationsReadAction() {
  const session = await getSession();
  if (!session) return;
  markAllNotificationsRead(session.userId);
  revalidatePath(`/${session.role}`);
}

'@
[System.IO.File]::WriteAllText("src/app/actions/notifications.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { requestApplicationFormAction } from "@/app/actions/student";
import type { FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function RequestFormButton() {
  const [state, formAction, pending] = useActionState(async (_prev: FormState) => requestApplicationFormAction(), initialState);

  if (state.success) {
    return <p className="text-sm text-teal">{state.success}</p>;
  }

  return (
    <form action={formAction}>
      <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
        {pending ? "Requesting..." : "Request application form"}
      </button>
      {state.error && <p className="text-sm text-red-700 mt-2">{state.error}</p>}
    </form>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/student/request-form-button.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
"use client";

import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { logoutAction } from "@/app/actions/auth";

// How long a portal can sit idle before automatically logging out.
const IDLE_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

const ACTIVITY_EVENTS = ["mousemove", "mousedown", "keydown", "scroll", "touchstart"] as const;

export function IdleLogout() {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const router = useRouter();

  useEffect(() => {
    function resetTimer() {
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(async () => {
        // logoutAction() calls redirect() internally, which is reliable when
        // triggered by a form submission but not guaranteed when called from
        // a plain timer callback like this - so clear the cookie server-side
        // via the action, then always force the navigation client-side too,
        // regardless of what the action's own redirect does.
        try {
          await logoutAction();
        } catch {
          // redirect() throws by design - ignore and fall through.
        }
        router.push("/login?reason=inactivity");
        router.refresh();
      }, IDLE_TIMEOUT_MS);
    }

    resetTimer();
    ACTIVITY_EVENTS.forEach((event) => window.addEventListener(event, resetTimer));

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      ACTIVITY_EVENTS.forEach((event) => window.removeEventListener(event, resetTimer));
    };
  }, [router]);

  return null;
}

'@
[System.IO.File]::WriteAllText("src/components/idle-logout.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import Link from "next/link";
import {
  getNotificationsAction,
  markNotificationReadAction,
  markAllNotificationsReadAction,
} from "@/app/actions/notifications";
import type { NotificationRecord } from "@/types";

const POLL_INTERVAL_MS = 20000;

export function NotificationBell() {
  const [notifications, setNotifications] = useState<NotificationRecord[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const refresh = useCallback(async () => {
    const result = await getNotificationsAction();
    setNotifications(result.notifications);
    setUnreadCount(result.unreadCount);
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  async function handleOpen(id: string) {
    await markNotificationReadAction(id);
    refresh();
  }

  async function handleMarkAllRead() {
    await markAllNotificationsReadAction();
    refresh();
  }

  return (
    <div className="relative" ref={containerRef}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="relative w-9 h-9 rounded-full grid place-items-center hover:bg-paper-dim transition-colors"
        aria-label="Notifications"
      >
        <svg viewBox="0 0 24 24" fill="none" className="w-5 h-5 text-ink/70" aria-hidden="true">
          <path
            d="M12 3a5 5 0 00-5 5v3.2c0 .53-.2 1.04-.56 1.42L5 14.2c-.9.95-.24 2.55 1.06 2.55h11.88c1.3 0 1.96-1.6 1.06-2.55l-1.44-1.58A2 2 0 0117 11.2V8a5 5 0 00-5-5z"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinejoin="round"
          />
          <path d="M9.5 19a2.5 2.5 0 005 0" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 bg-gold-deep text-paper text-[10px] leading-none rounded-full w-4 h-4 grid place-items-center">
            {unreadCount > 9 ? "9+" : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-80 max-h-96 overflow-y-auto bg-paper border border-line rounded-xl shadow-lg z-50">
          <div className="flex items-center justify-between px-4 py-3 border-b border-line">
            <p className="text-sm font-medium">Notifications</p>
            {unreadCount > 0 && (
              <button type="button" onClick={handleMarkAllRead} className="text-xs text-teal hover:underline">
                Mark all read
              </button>
            )}
          </div>
          {notifications.length === 0 ? (
            <p className="px-4 py-6 text-sm text-ink/50 italic text-center">No notifications yet.</p>
          ) : (
            <ul>
              {notifications.map((n) => (
                <li key={n.id} className="border-b border-line last:border-0">
                  <Link
                    href={n.link || "#"}
                    onClick={() => handleOpen(n.id)}
                    className={`block px-4 py-3 text-sm hover:bg-paper-dim transition-colors ${
                      n.read ? "" : "bg-teal/5"
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      {!n.read && <span className="w-1.5 h-1.5 rounded-full bg-teal mt-1.5 shrink-0" />}
                      <div className={n.read ? "pl-3.5" : ""}>
                        <p className="font-medium">{n.title}</p>
                        {n.body && <p className="text-ink/60 text-xs mt-0.5">{n.body}</p>}
                        <p className="text-ink/40 text-[11px] mt-1">{new Date(n.createdAt).toLocaleString()}</p>
                      </div>
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/components/notification-bell.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Add notifications, auto-logout, welcome email, form request flow; fix corrupted BOM project-wide"
git push

Write-Host 'Done. Files written and pushed.'