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

