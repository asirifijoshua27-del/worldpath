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
