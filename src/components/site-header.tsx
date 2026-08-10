"use client";

import { useState } from "react";
import Link from "next/link";
import { ApplyDropdown } from "@/components/apply-dropdown";

const NAV_LINKS = [
  { href: "/about", label: "About & Team" },
  { href: "/impact", label: "Impact" },
  { href: "/blog", label: "Blog" },
  { href: "/work-visa", label: "Work Visa" },
  { href: "/get-involved", label: "Get Involved" },
];

export function SiteHeader({ orgName, logoUrl }: { orgName: string; logoUrl?: string | null }) {
  const [mobileOpen, setMobileOpen] = useState(false);

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

        {/* Desktop nav links (Apply now + hamburger live outside this, so they're never duplicated per breakpoint) */}
        <nav className="hidden md:flex items-center gap-6 text-sm">
          {NAV_LINKS.map((l) => (
            <Link key={l.href} href={l.href} className="hover:text-gold-deep transition-colors">
              {l.label}
            </Link>
          ))}
          <Link href="/login" className="hover:text-gold-deep transition-colors">
            Log in
          </Link>
        </nav>

        <div className="flex items-center gap-3">
          <ApplyDropdown />
          <button
            type="button"
            onClick={() => setMobileOpen((v) => !v)}
            aria-label={mobileOpen ? "Close menu" : "Open menu"}
            aria-expanded={mobileOpen}
            className="w-9 h-9 grid place-items-center rounded-full hover:bg-paper-dim transition-colors md:hidden"
          >
            {mobileOpen ? (
              <svg viewBox="0 0 24 24" fill="none" className="w-5 h-5" aria-hidden="true">
                <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" fill="none" className="w-5 h-5" aria-hidden="true">
                <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Mobile menu panel */}
      {mobileOpen && (
        <nav className="md:hidden border-t border-line bg-paper px-6 py-4 flex flex-col gap-1">
          {NAV_LINKS.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              onClick={() => setMobileOpen(false)}
              className="py-2.5 text-sm hover:text-gold-deep transition-colors"
            >
              {l.label}
            </Link>
          ))}
          <Link
            href="/login"
            onClick={() => setMobileOpen(false)}
            className="py-2.5 text-sm hover:text-gold-deep transition-colors"
          >
            Log in
          </Link>
        </nav>
      )}
    </header>
  );
}
