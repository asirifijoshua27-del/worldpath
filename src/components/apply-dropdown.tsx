"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";

const APPLY_LINKS = [
  { href: "/register?level=undergrad", label: "Undergraduate" },
  { href: "/register?level=masters", label: "Master's" },
  { href: "/register?level=phd", label: "PhD" },
  { href: "/register", label: "Scholarships" },
  { href: "/register/work-visa", label: "Work Visa" },
];

export function ApplyDropdown({ className = "" }: { className?: string }) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div
      ref={containerRef}
      className={`relative ${className}`}
      onMouseEnter={() => setOpen(true)}
    >
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-haspopup="menu"
        aria-expanded={open}
        className="rounded-full bg-ink text-paper px-4 py-2 hover:bg-teal transition-colors"
      >
        Apply now
      </button>

      {open && (
        <div
          role="menu"
          className="absolute right-0 mt-2 w-52 bg-paper border border-line rounded-xl shadow-lg py-2 z-50"
        >
          {APPLY_LINKS.map((l) => (
            <Link
              key={l.label}
              href={l.href}
              role="menuitem"
              onClick={() => setOpen(false)}
              className="block px-4 py-2.5 text-sm hover:bg-paper-dim hover:text-gold-deep transition-colors"
            >
              {l.label}
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
