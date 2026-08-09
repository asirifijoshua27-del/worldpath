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
