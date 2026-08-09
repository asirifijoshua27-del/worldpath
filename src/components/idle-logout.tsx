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
