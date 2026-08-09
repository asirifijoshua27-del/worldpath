ï»¿import Link from "next/link";
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
            {name} Â· <span className="uppercase text-xs tracking-wide">{role}</span>
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


