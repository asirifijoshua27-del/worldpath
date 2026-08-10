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
