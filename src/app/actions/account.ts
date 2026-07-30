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

