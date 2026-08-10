# WorldPath Group - Work Visa nav link + Apply now dropdown menu, plus a
# real mobile hamburger menu (the site had none before - About & Team
# and Get Involved were previously unreachable on mobile with no way
# to access them; now everything is reachable).
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/register" | Out-Null
$content = @'
"use client";

import { useActionState, useRef, startTransition, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { registerAction, type FormState } from "@/app/actions/auth";
import { TARGET_LEVELS, TARGET_COUNTRIES, CURRENT_EDUCATION_LEVELS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";
import { ArrowRight } from "@/components/arrow-right";

const initialState: FormState = {};

function RegisterForm() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);
  const searchParams = useSearchParams();
  const levelParam = searchParams.get("level");
  const defaultLevel = TARGET_LEVELS.some((l) => l.value === levelParam) ? levelParam! : "undergrad";

  // React resets uncontrolled form fields the moment a <form action={...}>
  // submits - including on a failed submission. On a form this long,
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
            <select name="targetLevel" className="input" defaultValue={defaultLevel}>
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

export default function RegisterPage() {
  return (
    <Suspense fallback={null}>
      <RegisterForm />
    </Suspense>
  );
}


'@
[System.IO.File]::WriteAllText("src/app/register/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/components/site-header.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
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

'@
[System.IO.File]::WriteAllText("src/components/apply-dropdown.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Add Work Visa nav link, Apply now dropdown, and mobile hamburger menu"
git push

Write-Host 'Done. Files written and pushed.'