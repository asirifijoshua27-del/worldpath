# WorldPath Group - Phase 2a: real job listings database with full admin
# CRUD (create/edit/delete/publish/verify), replacing the honest empty
# state with real listings once you add them. Nothing is fabricated -
# the empty state still shows until you add real, verified jobs.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/admin" | Out-Null
$content = @'
import { getSession } from "@/lib/auth";
import { PortalNav } from "@/components/portal-nav";

const LINKS = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/content", label: "Site content" },
  { href: "/admin/staff", label: "Staff" },
  { href: "/admin/board", label: "Board" },
  { href: "/admin/students", label: "Students" },
  { href: "/admin/jobs", label: "Job listings" },
  { href: "/admin/blog", label: "Blog" },
  { href: "/admin/impact", label: "Impact stories" },
  { href: "/admin/leads", label: "Leads" },
  { href: "/admin/users", label: "Accounts" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <>
      <PortalNav role="admin" name={session?.name || "Admin"} links={LINKS} />
      <main className="flex-1 mx-auto max-w-6xl w-full px-6 py-10">{children}</main>
    </>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/layout.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/work-visa" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listPublishedJobs } from "@/lib/repo";
import { JOB_VERIFICATION_LABELS } from "@/types";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { CheckIcon } from "@/components/check-icon";
import { ArrowRight } from "@/components/arrow-right";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `International Careers & Work Visa Support | ${content.orgName}`,
    description:
      "WorldPath helps qualified applicants from Ghana explore legitimate employment opportunities in the USA, Germany and other international destinations, prepare strong job applications, and understand the relevant work-visa process.",
  };
}

const TRUST_POINTS = [
  "Helps applicants identify suitable international employment opportunities.",
  "Assesses applicants based on education, experience and skills.",
  "Supports CV/resume and cover-letter preparation.",
  "Helps applicants prepare job applications.",
  "Provides interview/application guidance.",
  "Provides general information about relevant work-visa routes.",
  "Directs applicants to legitimate employer and government resources.",
];

const DESTINATIONS = [
  {
    title: "United States",
    body: "Explore employment opportunities and career pathways in the United States.",
    categories: ["Technology", "Engineering", "Healthcare", "Education", "Research", "Skilled Trades", "Business", "Other eligible occupations"],
    cta: "Explore USA Jobs",
  },
  {
    title: "Germany",
    body: "Explore skilled employment opportunities and international career pathways in Germany.",
    categories: ["Engineering", "IT & Technology", "Healthcare", "Skilled Trades", "Research", "Manufacturing", "Construction", "Other eligible occupations"],
    cta: "Explore Germany Jobs",
  },
  {
    title: "Other Destinations",
    body: "Explore additional international employment opportunities as the WorldPath network expands.",
    categories: [],
    cta: "Explore Opportunities",
  },
];

const PROCESS_STEPS = [
  { title: "Create Your Profile", body: "Applicants provide their education, work experience, skills, career interests and destination preferences." },
  { title: "Profile Assessment", body: "WorldPath reviews the applicant's information and identifies potentially suitable international career opportunities." },
  { title: "Opportunity Matching", body: "Applicants are matched with relevant opportunities based on their qualifications and experience." },
  { title: "Application Preparation", body: "WorldPath assists with CV/resume preparation, cover letters, application forms and supporting documents." },
  { title: "Employer Application & Interview", body: "Applicants apply to employers and participate directly in employer interviews and recruitment processes." },
  { title: "Visa Guidance", body: "After an eligible employment offer, WorldPath provides general guidance and directs applicants toward the appropriate official visa/residence resources." },
];

const SERVICES = [
  { title: "Career Opportunity Search", body: "Find potentially relevant international employment opportunities." },
  { title: "CV & Resume Support", body: "Prepare a professional CV suited to international applications." },
  { title: "Cover Letter Support", body: "Create targeted cover letters for specific opportunities." },
  { title: "Application Support", body: "Help applicants understand and complete job applications." },
  { title: "Interview Preparation", body: "Prepare applicants for international employer interviews." },
  { title: "Visa Information", body: "Provide general information and official resources for relevant work-visa pathways." },
];

const CREDIBILITY = [
  { title: "Ghana-Based Support", body: "Providing structured career support for applicants from Ghana." },
  { title: "International Opportunities", body: "Connecting applicants with opportunities beyond Ghana." },
  { title: "Application Guidance", body: "Helping applicants prepare stronger international job applications." },
  { title: "Opportunity Verification", body: "Prioritizing legitimate employer and official sources." },
  { title: "Transparent Process", body: "No guarantees of employment or visa approval." },
];

const SCAM_WARNINGS = [
  "Guaranteed employment",
  "Guaranteed visa approval",
  "Guaranteed sponsorship",
  "Fake employment contracts",
  "Requests for large payments to \"secure\" a job",
  "Unofficial visa processing",
  "Requests to send money to personal accounts",
];

const FAQS = [
  { q: "Can WorldPath guarantee me a job?", a: "No. WorldPath can help applicants identify and apply for relevant opportunities, but employment decisions are made by employers." },
  { q: "Can WorldPath guarantee my visa?", a: "No. Visa decisions are made by the relevant immigration authorities." },
  { q: "Do all jobs provide visa sponsorship?", a: "No. Sponsorship or work authorization depends on the employer, position, country and applicable immigration rules." },
  { q: "Can I apply from Ghana?", a: "Yes, applicants can explore opportunities while residing in Ghana, subject to the requirements of the specific employer and destination." },
  { q: "Do I need work experience?", a: "Requirements vary by position. Some opportunities may accept recent graduates or entry-level applicants." },
  { q: "Can students apply?", a: "This depends on the opportunity and its eligibility requirements." },
  { q: "Can WorldPath help me prepare my CV?", a: "Yes." },
  { q: "Can WorldPath help me prepare for interviews?", a: "Yes." },
];

export default function WorkVisaPage() {
  const content = getSiteContent();
  const jobs = listPublishedJobs();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        {/* Hero */}
        <section className="relative bg-navy text-paper overflow-hidden">
          <div
            className="absolute inset-0 opacity-40"
            style={{ background: "radial-gradient(ellipse 90% 60% at 50% -10%, rgba(15,110,140,0.55), transparent 60%)" }}
          />
          <div className="relative mx-auto max-w-4xl px-6 pt-24 pb-20 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">International Careers & Work Visa Support</p>
            <h1 className="font-display text-4xl sm:text-5xl leading-[1.12] mt-5">Find Your Next Opportunity Abroad</h1>
            <p className="mt-6 text-lg text-paper/75 max-w-2xl mx-auto leading-relaxed">
              WorldPath helps qualified applicants from Ghana explore legitimate employment opportunities in the
              USA, Germany and other international destinations, prepare strong job applications, and understand
              the relevant work-visa process.
            </p>
            <div className="mt-9 flex flex-wrap justify-center gap-4">
              <a href="#opportunities" className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors">
                Explore Jobs
              </a>
              <Link href="/register/work-visa" className="rounded-full border border-paper/30 px-7 py-3 hover:border-paper/70 transition-colors">
                Get Your Profile Assessed
              </Link>
            </div>
          </div>
        </section>

        {/* Trust statement */}
        <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3 text-center">What we do</p>
          <h2 className="font-display text-2xl sm:text-3xl mb-8 text-center">
            Career Opportunities. Application Support. Responsible Visa Guidance.
          </h2>
          <ul className="grid sm:grid-cols-2 gap-x-8 gap-y-3 mb-8">
            {TRUST_POINTS.map((point) => (
              <li key={point} className="flex gap-3 text-sm text-ink/80">
                <span className="w-5 h-5 rounded-full bg-teal/10 text-teal grid place-items-center shrink-0 mt-0.5">
                  <CheckIcon className="w-3 h-3" />
                </span>
                {point}
              </li>
            ))}
          </ul>
          <div className="rounded-xl border border-line bg-paper-dim px-5 py-4 text-sm text-ink/80 leading-relaxed">
            <strong>WorldPath does not guarantee employment, employer sponsorship, or visa approval.</strong> Employment
            decisions are made by employers and immigration decisions are made by the relevant government authorities.
          </div>
        </section>

        {/* Destination cards */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Where you could go</p>
          <h2 className="font-display text-3xl mb-10">Choose Your Destination</h2>
          <div className="grid sm:grid-cols-3 gap-6">
            {DESTINATIONS.map((d) => (
              <div key={d.title} className="border border-line rounded-xl p-6 flex flex-col">
                <h3 className="font-display text-xl mb-2">{d.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed mb-4">{d.body}</p>
                {d.categories.length > 0 && (
                  <ul className="text-xs text-ink/60 space-y-1 mb-6">
                    {d.categories.map((c) => (
                      <li key={c}>{c}</li>
                    ))}
                  </ul>
                )}
                <a href="#opportunities" className="mt-auto text-sm text-teal hover:underline inline-flex items-center">
                  {d.cta}
                  <ArrowRight />
                </a>
              </div>
            ))}
          </div>
        </section>

        {/* How WorldPath works */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">The process</p>
          <h2 className="font-display text-3xl mb-10">How WorldPath Works</h2>
          <div className="grid sm:grid-cols-3 gap-x-8 gap-y-10">
            {PROCESS_STEPS.map((step, i) => (
              <div key={step.title}>
                <span className="font-display text-2xl text-gold-deep">{String(i + 1).padStart(2, "0")}</span>
                <h3 className="font-medium mt-2 mb-1.5">{step.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed">{step.body}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Current opportunities - honest empty state, never fabricated listings */}
        <section id="opportunities" className="mx-auto max-w-6xl px-6 py-16 border-b border-line scroll-mt-16">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Open roles</p>
          <h2 className="font-display text-3xl mb-6">Current International Opportunities</h2>
          {jobs.length === 0 ? (
            <div className="border border-dashed border-line rounded-xl p-10 text-center">
              <p className="text-ink/70 max-w-md mx-auto leading-relaxed">
                No verified opportunities are listed yet. Get your profile assessed so our team can reach out
                when a suitable opportunity is confirmed.
              </p>
              <Link href="/register/work-visa" className="inline-block mt-5 text-sm text-teal hover:underline">
                Get Your Profile Assessed
                <ArrowRight />
              </Link>
            </div>
          ) : (
            <div className="grid sm:grid-cols-2 gap-6">
              {jobs.map((job) => (
                <div key={job.id} className="border border-line rounded-xl p-6">
                  <div className="flex items-start justify-between gap-3 mb-1">
                    <h3 className="font-display text-lg">{job.title}</h3>
                    <span className="text-[11px] uppercase tracking-wide text-teal shrink-0 mt-1">
                      {JOB_VERIFICATION_LABELS[job.verificationStatus]}
                    </span>
                  </div>
                  <p className="text-sm text-ink/70 mb-3">
                    {job.employer} &middot; {job.country}
                    {job.city ? `, ${job.city}` : ""}
                  </p>
                  <ul className="text-xs text-ink/60 space-y-1 mb-4">
                    {job.industry && <li>{job.industry}</li>}
                    {job.experienceRequired && <li>{job.experienceRequired}</li>}
                    {job.educationRequirement && <li>{job.educationRequirement}</li>}
                    {job.languageRequirement && <li>{job.languageRequirement}</li>}
                    {job.salary && <li>{job.salary}</li>}
                  </ul>
                  {job.sponsorshipInfo && (
                    <p className="text-xs text-ink/70 mb-1">
                      <strong>Sponsorship:</strong> {job.sponsorshipInfo}
                    </p>
                  )}
                  {job.lastVerifiedDate && (
                    <p className="text-xs text-ink/50 mb-4">
                      Verified: {new Date(job.lastVerifiedDate).toLocaleDateString("en-US", { month: "long", year: "numeric" })}
                    </p>
                  )}
                  {job.applicationUrl ? (
                    <a
                      href={job.applicationUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-teal hover:underline inline-flex items-center"
                    >
                      View Opportunity
                      <ArrowRight />
                    </a>
                  ) : (
                    <Link href="/register/work-visa" className="text-sm text-teal hover:underline inline-flex items-center">
                      Get Your Profile Assessed
                      <ArrowRight />
                    </Link>
                  )}
                </div>
              ))}
            </div>
          )}
        </section>

        {/* Profile assessment CTA */}
        <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line text-center">
          <h2 className="font-display text-2xl sm:text-3xl mb-3">Not Sure Where You Qualify?</h2>
          <p className="text-ink/70 leading-relaxed max-w-xl mx-auto mb-6">
            Tell us about your education, experience and career goals. Our team will help you understand which
            international opportunities may be relevant to your profile.
          </p>
          <Link href="/register/work-visa" className="btn-primary inline-block">
            Start Profile Assessment
          </Link>
        </section>

        {/* Scam protection */}
        <section id="scam-awareness" className="mx-auto max-w-4xl px-6 py-16 border-b border-line scroll-mt-16">
          <div className="rounded-2xl border border-red-200 bg-red-50 px-6 py-8 sm:px-10 sm:py-10">
            <h2 className="font-display text-2xl mb-4 text-red-900">Protect Yourself From Job & Visa Scams</h2>
            <p className="text-sm text-red-900/80 mb-4">Be cautious of anyone promising:</p>
            <ul className="grid sm:grid-cols-2 gap-x-8 gap-y-2 mb-6">
              {SCAM_WARNINGS.map((w) => (
                <li key={w} className="text-sm text-red-900/80">
                  &bull; {w}
                </li>
              ))}
            </ul>
            <p className="text-sm font-medium text-red-900 mb-4">
              WorldPath does not guarantee employment, sponsorship or visa approval. Always verify employment
              offers and immigration information through official sources.
            </p>
            <div className="flex flex-wrap gap-4 text-sm">
              <a href="https://www.uscis.gov" target="_blank" rel="noopener noreferrer" className="text-red-900 underline hover:no-underline">
                USCIS (United States)
              </a>
              <a href="https://www.make-it-in-germany.com" target="_blank" rel="noopener noreferrer" className="text-red-900 underline hover:no-underline">
                Make it in Germany
              </a>
            </div>
          </div>
        </section>

        {/* USA & Germany info */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Destination guides</p>
          <h2 className="font-display text-3xl mb-10">Understanding Your Destination</h2>
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <h3 className="font-display text-xl mb-3">United States</h3>
              <ul className="text-sm text-ink/70 space-y-1.5 mb-4">
                <li>Employment-based immigration</li>
                <li>Employer-sponsored employment</li>
                <li>Temporary work visas</li>
                <li>General eligibility considerations</li>
                <li>Application process overview</li>
              </ul>
              <p className="text-xs text-ink/50 leading-relaxed mb-3">
                Requirements vary by visa category and applicant circumstances.
              </p>
              <a href="https://www.uscis.gov" target="_blank" rel="noopener noreferrer" className="text-sm text-teal hover:underline">
                Official USCIS resources
                <ArrowRight />
              </a>
            </div>
            <div>
              <h3 className="font-display text-xl mb-3">Germany</h3>
              <ul className="text-sm text-ink/70 space-y-1.5 mb-4">
                <li>Skilled-worker immigration</li>
                <li>EU Blue Card</li>
                <li>Employment residence permits</li>
                <li>Recognition of qualifications where applicable</li>
                <li>Language considerations</li>
              </ul>
              <p className="text-xs text-ink/50 leading-relaxed mb-3">
                Requirements vary by visa category and applicant circumstances. This is general information, not
                legal advice.
              </p>
              <a href="https://www.make-it-in-germany.com" target="_blank" rel="noopener noreferrer" className="text-sm text-teal hover:underline">
                Official Make it in Germany resources
                <ArrowRight />
              </a>
            </div>
          </div>
        </section>

        {/* Services */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Support</p>
          <h2 className="font-display text-3xl mb-10">How We Support Applicants</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {SERVICES.map((s) => (
              <div key={s.title} className="border border-line rounded-xl p-5">
                <h3 className="font-medium mb-1.5">{s.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed">{s.body}</p>
              </div>
            ))}
          </div>
          <p className="text-xs text-ink/50 mt-8 max-w-2xl">
            Payment for WorldPath services does not guarantee employment, employer sponsorship or visa approval.
          </p>
        </section>

        {/* FAQ */}
        <section className="mx-auto max-w-3xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Questions</p>
          <h2 className="font-display text-3xl mb-8">Frequently Asked Questions</h2>
          <div className="divide-y divide-line border-t border-b border-line">
            {FAQS.map((f) => (
              <details key={f.q} className="group py-4">
                <summary className="flex items-center justify-between cursor-pointer list-none font-medium text-sm">
                  {f.q}
                  <span className="text-ink/40 group-open:rotate-45 transition-transform text-lg leading-none">+</span>
                </summary>
                <p className="text-sm text-ink/70 mt-2 leading-relaxed">{f.a}</p>
              </details>
            ))}
          </div>
        </section>

        {/* Credibility */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Why WorldPath</p>
          <h2 className="font-display text-3xl mb-10">Why WorldPath?</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {CREDIBILITY.map((c) => (
              <div key={c.title} className="border border-line rounded-xl p-5">
                <h3 className="font-medium mb-1.5">{c.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed">{c.body}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Closing CTA */}
        <section className="mx-auto max-w-6xl px-6 py-16">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-2xl mb-2">Ready to get started?</h2>
              <p className="text-paper/75 max-w-md">
                Tell us about your background and we'll help you understand where you may fit.
              </p>
            </div>
            <Link
              href="/register/work-visa"
              className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center"
            >
              Get Your Profile Assessed
            </Link>
          </div>
          <p className="text-xs text-ink/40 mt-6 max-w-2xl">
            WorldPath provides career support and general information, not legal or immigration advice. Employment
            and visa decisions are made solely by employers and the relevant government authorities. Always verify
            opportunities and requirements through official sources.
          </p>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/work-visa/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import fs from "node:fs";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";

// This project uses Node's built-in `node:sqlite` module as its database
// driver so the app runs with zero native-binary installs. The data model
// mirrors docs/schema.prisma.reference exactly, so migrating to Prisma +
// Postgres later is a mechanical port, not a redesign. See README.md.

const DB_PATH = process.env.DATABASE_FILE || path.join(process.cwd(), "data", "worldpath.db");

function getDb(): DatabaseSync {
  const g = globalThis as unknown as { __worldpathDb?: DatabaseSync };
  if (g.__worldpathDb) return g.__worldpathDb;

  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const db = new DatabaseSync(DB_PATH);
  db.exec("PRAGMA journal_mode = WAL;");
  db.exec("PRAGMA foreign_keys = ON;");
  migrate(db);
  seed(db);
  g.__worldpathDb = db;
  return db;
}

function migrate(db: DatabaseSync) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      passwordHash TEXT,
      role TEXT NOT NULL DEFAULT 'student',
      name TEXT NOT NULL,
      emailVerified INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS staff_profiles (
      id TEXT PRIMARY KEY,
      userId TEXT UNIQUE REFERENCES users(id),
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS board_members (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS students (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE NOT NULL,
      userId TEXT UNIQUE NOT NULL REFERENCES users(id),
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      targetCountries TEXT NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'new',
      assignedStaffId TEXT REFERENCES staff_profiles(id),
      documents TEXT NOT NULL DEFAULT '[]',
      scholarshipInterest INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS student_notes (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      authorId TEXT NOT NULL REFERENCES users(id),
      text TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS site_content (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      orgName TEXT NOT NULL DEFAULT 'WorldPath Group',
      tagline TEXT NOT NULL DEFAULT '',
      mission TEXT NOT NULL DEFAULT '',
      vision TEXT NOT NULL DEFAULT '',
      contactEmail TEXT NOT NULL DEFAULT '',
      contactPhone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS email_verifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT UNIQUE NOT NULL,
      expiresAt TEXT NOT NULL,
      used INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS counters (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      link TEXT,
      read INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      employer TEXT NOT NULL,
      country TEXT NOT NULL,
      city TEXT NOT NULL DEFAULT '',
      industry TEXT NOT NULL DEFAULT '',
      employmentType TEXT NOT NULL DEFAULT '',
      experienceRequired TEXT NOT NULL DEFAULT '',
      educationRequirement TEXT NOT NULL DEFAULT '',
      languageRequirement TEXT NOT NULL DEFAULT '',
      salary TEXT NOT NULL DEFAULT '',
      sponsorshipInfo TEXT NOT NULL DEFAULT '',
      applicationDeadline TEXT,
      lastVerifiedDate TEXT,
      source TEXT NOT NULL DEFAULT '',
      verificationStatus TEXT NOT NULL DEFAULT 'pending_verification',
      applicationUrl TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS blog_posts (
      id TEXT PRIMARY KEY,
      slug TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      excerpt TEXT NOT NULL DEFAULT '',
      body TEXT NOT NULL DEFAULT '',
      coverImageUrl TEXT,
      tags TEXT NOT NULL DEFAULT '[]',
      authorName TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      publishedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS impact_stories (
      id TEXT PRIMARY KEY,
      studentName TEXT NOT NULL,
      headline TEXT NOT NULL,
      story TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      destinationCountry TEXT NOT NULL DEFAULT '',
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      featured INTEGER NOT NULL DEFAULT 0,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS volunteer_leads (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL DEFAULT 'volunteer',
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      message TEXT NOT NULL DEFAULT '',
      handled INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  `);

  // Columns added after the initial release go here as best-effort ALTERs
  // (existing databases won't have them; CREATE TABLE IF NOT EXISTS above
  // only helps brand-new installs). Safe to ignore "duplicate column".
  const alters = [
    "ALTER TABLE site_content ADD COLUMN donateInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN logoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN caretakingInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE student_notes ADD COLUMN attachmentUrl TEXT",
    "ALTER TABLE students ADD COLUMN currentEducationLevel TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN schoolName TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationType TEXT NOT NULL DEFAULT 'standard'",
    "ALTER TABLE students ADD COLUMN photoUrl TEXT",
    "ALTER TABLE volunteer_leads ADD COLUMN areasOfInterest TEXT NOT NULL DEFAULT '[]'",
    "ALTER TABLE volunteer_leads ADD COLUMN availability TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN heroImageUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN founderName TEXT NOT NULL DEFAULT 'Cyril Asirifi Kwame'",
    "ALTER TABLE site_content ADD COLUMN founderTitle TEXT NOT NULL DEFAULT 'Founder & Executive Director'",
    "ALTER TABLE site_content ADD COLUMN founderBio TEXT NOT NULL DEFAULT 'Passionate about expanding access to international education and scholarship opportunities for students across Ghana.'",
    "ALTER TABLE site_content ADD COLUMN founderPhotoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN undergradInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN mastersInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN phdInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN scholarshipsInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN workVisaInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationTrack TEXT NOT NULL DEFAULT 'university'",
    "ALTER TABLE students ADD COLUMN profession TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN currentOccupation TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN yearsExperience TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN hasJobOffer INTEGER NOT NULL DEFAULT 0",
  ];
  for (const sql of alters) {
    try {
      db.exec(sql);
    } catch {
      // Column already exists ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â fine.
    }
  }
}

function seed(db: DatabaseSync) {
  const now = new Date().toISOString();

  const contentRow = db.prepare("SELECT id FROM site_content WHERE id = 1").get();
  if (!contentRow) {
    db.prepare(
      `INSERT INTO site_content (id, orgName, tagline, mission, vision, contactEmail, contactPhone, address, donateInfo, caretakingInfo)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      "WorldPath Group",
      "Opening the world's classrooms to Ghana's brightest students.",
      "WorldPath Group helps talented undergraduate, master's, and PhD students across Ghana apply to universities abroad and secure the scholarships that make it possible \u2014 with priority access for students whose families cannot otherwise afford it, including orphans.",
      "A future where a student's potential, not their family's income, determines which universities are open to them.",
      "hello@worldpathgroup.org",
      "",
      "Accra, Ghana",
      "Update this from Admin \u2192 Site content with your bank account or mobile money details.",
      "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities \u2014 because a student's wellbeing at home is part of their path to university too."
    );
  }

  const adminRow = db.prepare("SELECT id FROM users WHERE role = 'admin' LIMIT 1").get();
  if (!adminRow) {
    const id = randomUUID();
    const passwordHash = bcrypt.hashSync("ChangeMe123!", 10);
    db.prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, 'admin', ?, 1, ?, ?)`
    ).run(id, "admin", "admin@worldpathgroup.org", passwordHash, "WorldPath Admin", now, now);
  }
}

// node:sqlite returns row objects with a null prototype. That's invisible
// almost everywhere, but React Server Components refuse to serialize
// null-prototype objects when passing data to Client Components ("Only
// plain objects... can be passed"). This thin wrapper spreads every row
// into a genuine plain object so callers never have to think about it.
type SQLInputValue = null | number | bigint | string | NodeJS.ArrayBufferView;

interface PlainStatement {
  get(...params: SQLInputValue[]): Record<string, unknown> | undefined;
  all(...params: SQLInputValue[]): Record<string, unknown>[];
  run(...params: SQLInputValue[]): unknown;
}

interface PlainDb {
  prepare(sql: string): PlainStatement;
}

function wrapDb(raw: DatabaseSync): PlainDb {
  return {
    prepare(sql: string) {
      const stmt = raw.prepare(sql);
      return {
        get: (...params: SQLInputValue[]) => {
          const row = stmt.get(...params);
          return row ? { ...(row as object) } : undefined;
        },
        all: (...params: SQLInputValue[]) => {
          return stmt.all(...params).map((row) => ({ ...(row as object) }));
        },
        run: (...params: SQLInputValue[]) => stmt.run(...params),
      };
    },
  };
}

export function db(): PlainDb {
  return wrapDb(getDb());
}

/**
 * Temporarily disables foreign key enforcement, runs fn, then re-enables it.
 * Used only for account deletion: a deleted staff/admin's authored messages
 * are kept (for the student's record) rather than deleted, which would
 * otherwise violate the foreign key on student_notes.authorId.
 */
export function withForeignKeysOff<T>(fn: () => T): T {
  const raw = getDb();
  raw.exec("PRAGMA foreign_keys = OFF;");
  try {
    return fn();
  } finally {
    raw.exec("PRAGMA foreign_keys = ON;");
  }
}

export function nowIso(): string {
  return new Date().toISOString();
}

export function newId(): string {
  return randomUUID();
}

/** Generates the next sequential student code for the current year, e.g. WPG-2026-0001 */
export function nextStudentCode(): string {
  const year = new Date().getFullYear();
  const counterId = `student-${year}`;
  const database = getDb();
  const existing = database.prepare("SELECT value FROM counters WHERE id = ?").get(counterId) as
    | { value: number }
    | undefined;
  const next = (existing?.value ?? 0) + 1;
  if (existing) {
    database.prepare("UPDATE counters SET value = ? WHERE id = ?").run(next, counterId);
  } else {
    database.prepare("INSERT INTO counters (id, value) VALUES (?, ?)").run(counterId, next);
  }
  return `WPG-${year}-${String(next).padStart(4, "0")}`;
}


'@
[System.IO.File]::WriteAllText("src/lib/db.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { db, newId, nowIso, nextStudentCode, withForeignKeysOff } from "@/lib/db";
import type {
  UserRecord,
  StaffProfileRecord,
  BoardMemberRecord,
  StudentRecord,
  StudentNoteRecord,
  SiteContentRecord,
  BlogPostRecord,
  ImpactStoryRecord,
  VolunteerLeadRecord,
  LeadType,
  Role,
  TargetLevel,
  DocumentItem,
  NotificationRecord,
  NotificationType,
  JobRecord,
  JobVerificationStatus,
} from "@/types";

const DEFAULT_CHECKLIST: DocumentItem[] = [
  { name: "Passport / national ID", done: false },
  { name: "Academic transcripts", done: false },
  { name: "Personal statement / essay", done: false },
  { name: "Recommendation letters", done: false },
  { name: "English proficiency test (if required)", done: false },
  { name: "Financial / sponsorship documents", done: false },
];

const WORK_VISA_CHECKLIST: DocumentItem[] = [
  { name: "Passport", done: false },
  { name: "CV / resume", done: false },
  { name: "Professional qualification / certification", done: false },
  { name: "Reference letters from past employers", done: false },
  { name: "Language proficiency test (if required)", done: false },
  { name: "Job offer letter (if you have one)", done: false },
  { name: "Police clearance certificate", done: false },
  { name: "Medical certificate", done: false },
];

// ---------- Users ----------

export function getUserByEmail(email: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE email = ?").get(email) as UserRecord | undefined;
}

export function getUserByUsername(username: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE username = ?").get(username) as UserRecord | undefined;
}

export function getUserById(id: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE id = ?").get(id) as UserRecord | undefined;
}

export function listUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users ORDER BY createdAt DESC").all() as unknown as UserRecord[];
}

export function countAdmins(): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM users WHERE role = 'admin'").get() as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

/**
 * Deletes a user account and whatever it owns: for staff, their public
 * profile (and unassigns any students); for students, their application
 * record. Messages the account authored are kept for the record ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â see
 * listNotesForStudent ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â rather than deleted.
 */
export function deleteUserAccount(userId: string): { staffPhotoUrl: string | null; studentPhotoUrl: string | null; documentUrls: string[] } {
  const database = db();
  let staffPhotoUrl: string | null = null;
  let studentPhotoUrl: string | null = null;
  let documentUrls: string[] = [];

  withForeignKeysOff(() => {
    const staff = database.prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
      | StaffProfileRecord
      | undefined;
    if (staff) {
      staffPhotoUrl = staff.photoUrl;
      database.prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(staff.id);
      database.prepare("DELETE FROM staff_profiles WHERE id = ?").run(staff.id);
    }

    const student = database.prepare("SELECT * FROM students WHERE userId = ?").get(userId) as
      | StudentRecord
      | undefined;
    if (student) {
      studentPhotoUrl = student.photoUrl;
      documentUrls = (JSON.parse(student.documents) as { fileUrl?: string | null }[])
        .map((d) => d.fileUrl)
        .filter((u): u is string => Boolean(u));
      database.prepare("DELETE FROM students WHERE id = ?").run(student.id);
    }

    database.prepare("DELETE FROM email_verifications WHERE userId = ?").run(userId);
    database.prepare("DELETE FROM users WHERE id = ?").run(userId);
  });

  return { staffPhotoUrl, studentPhotoUrl, documentUrls };
}

export function createUser(input: {
  username: string;
  email: string;
  name: string;
  role: Role;
  passwordHash?: string | null;
  emailVerified?: boolean;
}): UserRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.username,
      input.email,
      input.passwordHash ?? null,
      input.role,
      input.name,
      input.emailVerified ? 1 : 0,
      now,
      now
    );
  return getUserById(id)!;
}

export function setUserPassword(userId: string, passwordHash: string) {
  db()
    .prepare("UPDATE users SET passwordHash = ?, updatedAt = ? WHERE id = ?")
    .run(passwordHash, nowIso(), userId);
}

export function markEmailVerified(userId: string) {
  db().prepare("UPDATE users SET emailVerified = 1, updatedAt = ? WHERE id = ?").run(nowIso(), userId);
}

// ---------- Email verification tokens ----------

export function createVerificationToken(userId: string, token: string, ttlHours = 48) {
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();
  db()
    .prepare(
      `INSERT INTO email_verifications (id, userId, token, expiresAt, used, createdAt)
       VALUES (?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), userId, token, expiresAt, nowIso());
}

export function getVerificationToken(token: string) {
  return db().prepare("SELECT * FROM email_verifications WHERE token = ?").get(token) as
    | { id: string; userId: string; token: string; expiresAt: string; used: number }
    | undefined;
}

export function consumeVerificationToken(token: string) {
  db().prepare("UPDATE email_verifications SET used = 1 WHERE token = ?").run(token);
}

// ---------- Staff profiles ----------

export function listStaff(): StaffProfileRecord[] {
  return db().prepare("SELECT * FROM staff_profiles ORDER BY sortOrder ASC, name ASC").all() as unknown as StaffProfileRecord[];
}

export function getStaffById(id: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE id = ?").get(id) as StaffProfileRecord | undefined;
}

export function getStaffByUserId(userId: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
    | StaffProfileRecord
    | undefined;
}

export function createStaff(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  userId?: string | null;
  sortOrder?: number;
}): StaffProfileRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO staff_profiles (id, userId, name, title, bio, photoUrl, sortOrder)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(id, input.userId ?? null, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getStaffById(id)!;
}

export function updateStaff(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(
      `UPDATE staff_profiles SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`
    )
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteStaff(id: string) {
  db().prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(id);
  db().prepare("DELETE FROM staff_profiles WHERE id = ?").run(id);
}

// ---------- Board members ----------

export function listBoardMembers(): BoardMemberRecord[] {
  return db().prepare("SELECT * FROM board_members ORDER BY sortOrder ASC, name ASC").all() as unknown as BoardMemberRecord[];
}

export function getBoardMemberById(id: string): BoardMemberRecord | undefined {
  return db().prepare("SELECT * FROM board_members WHERE id = ?").get(id) as BoardMemberRecord | undefined;
}

export function createBoardMember(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  sortOrder?: number;
}): BoardMemberRecord {
  const id = newId();
  db()
    .prepare(`INSERT INTO board_members (id, name, title, bio, photoUrl, sortOrder) VALUES (?, ?, ?, ?, ?, ?)`)
    .run(id, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getBoardMemberById(id)!;
}

export function updateBoardMember(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(`UPDATE board_members SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`)
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteBoardMember(id: string) {
  db().prepare("DELETE FROM board_members WHERE id = ?").run(id);
}

// ---------- Students ----------

export function listStudents(): StudentRecord[] {
  return db().prepare("SELECT * FROM students ORDER BY createdAt DESC").all() as unknown as StudentRecord[];
}

export function listStudentsByStaff(staffId: string): StudentRecord[] {
  return db()
    .prepare("SELECT * FROM students WHERE assignedStaffId = ? ORDER BY createdAt DESC")
    .all(staffId) as unknown as StudentRecord[];
}

export function getStudentById(id: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE id = ?").get(id) as StudentRecord | undefined;
}

export function getStudentByUserId(userId: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE userId = ?").get(userId) as StudentRecord | undefined;
}

export function createStudentForUser(input: {
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string[];
  scholarshipInterest: boolean;
  currentEducationLevel?: string;
  schoolName?: string;
  applicationType?: "standard" | "free_shs";
  photoUrl?: string | null;
  applicationTrack?: "university" | "work_visa";
  profession?: string;
  currentOccupation?: string;
  yearsExperience?: string;
  hasJobOffer?: boolean;
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  const track = input.applicationTrack ?? "university";
  const checklist = track === "work_visa" ? WORK_VISA_CHECKLIST : DEFAULT_CHECKLIST;
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, photoUrl, applicationTrack, profession, currentOccupation, yearsExperience, hasJobOffer, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      code,
      input.userId,
      input.targetLevel,
      JSON.stringify(input.targetCountries),
      JSON.stringify(checklist),
      input.scholarshipInterest ? 1 : 0,
      input.currentEducationLevel ?? "",
      input.schoolName ?? "",
      input.applicationType ?? "standard",
      input.photoUrl ?? null,
      track,
      input.profession ?? "",
      input.currentOccupation ?? "",
      input.yearsExperience ?? "",
      input.hasJobOffer ? 1 : 0,
      now,
      now
    );
  return getStudentById(id)!;
}

export function updateStudentStatus(id: string, status: string) {
  db().prepare("UPDATE students SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function assignStudentStaff(id: string, staffId: string | null) {
  db().prepare("UPDATE students SET assignedStaffId = ?, updatedAt = ? WHERE id = ?").run(staffId, nowIso(), id);
}

export function updateStudentDocuments(id: string, documents: DocumentItem[]) {
  db()
    .prepare("UPDATE students SET documents = ?, updatedAt = ? WHERE id = ?")
    .run(JSON.stringify(documents), nowIso(), id);
}

export function updateStudentTargets(
  id: string,
  input: { targetLevel: TargetLevel; targetCountries: string[]; scholarshipInterest: boolean }
) {
  db()
    .prepare(
      "UPDATE students SET targetLevel = ?, targetCountries = ?, scholarshipInterest = ?, updatedAt = ? WHERE id = ?"
    )
    .run(input.targetLevel, JSON.stringify(input.targetCountries), input.scholarshipInterest ? 1 : 0, nowIso(), id);
}

// ---------- Student notes ----------

export function listNotesForStudent(
  studentId: string
): (StudentNoteRecord & { authorName: string; authorRole: Role })[] {
  return db()
    .prepare(
      `SELECT n.*, COALESCE(u.name, 'Former team member') as authorName, COALESCE(u.role, 'staff') as authorRole
       FROM student_notes n
       LEFT JOIN users u ON u.id = n.authorId
       WHERE n.studentId = ? ORDER BY n.createdAt ASC`
    )
    .all(studentId) as unknown as (StudentNoteRecord & { authorName: string; authorRole: Role })[];
}

export function addNote(studentId: string, authorId: string, text: string, attachmentUrl?: string | null) {
  db()
    .prepare(
      `INSERT INTO student_notes (id, studentId, authorId, text, attachmentUrl, createdAt) VALUES (?, ?, ?, ?, ?, ?)`
    )
    .run(newId(), studentId, authorId, text, attachmentUrl ?? null, nowIso());
}

// ---------- Site content ----------

export function getSiteContent(): SiteContentRecord {
  return db().prepare("SELECT * FROM site_content WHERE id = 1").get() as unknown as SiteContentRecord;
}

export function updateSiteContent(input: Omit<SiteContentRecord, "id">) {
  db()
    .prepare(
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, founderName = ?, founderTitle = ?, founderBio = ?, founderPhotoUrl = ?, undergradInfo = ?, mastersInfo = ?, phdInfo = ?, scholarshipsInfo = ?, workVisaInfo = ?, caretakingInfo = ?
       WHERE id = 1`
    )
    .run(
      input.orgName,
      input.tagline,
      input.mission,
      input.vision,
      input.contactEmail,
      input.contactPhone,
      input.address,
      input.donateInfo,
      input.logoUrl,
      input.heroImageUrl,
      input.founderName,
      input.founderTitle,
      input.founderBio,
      input.founderPhotoUrl,
      input.undergradInfo,
      input.mastersInfo,
      input.phdInfo,
      input.scholarshipsInfo,
      input.workVisaInfo,
      input.caretakingInfo
    );
}

// ---------- Blog posts ----------

function slugify(title: string): string {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .slice(0, 80);
}

export function uniqueSlug(title: string, excludeId?: string): string {
  const base = slugify(title) || "post";
  let slug = base;
  let n = 1;
  while (true) {
    const existing = db().prepare("SELECT id FROM blog_posts WHERE slug = ?").get(slug) as
      | { id: string }
      | undefined;
    if (!existing || existing.id === excludeId) return slug;
    n += 1;
    slug = `${base}-${n}`;
  }
}

export function listPublishedPosts(): BlogPostRecord[] {
  return db()
    .prepare("SELECT * FROM blog_posts WHERE published = 1 ORDER BY publishedAt DESC")
    .all() as unknown as BlogPostRecord[];
}

export function listAllPosts(): BlogPostRecord[] {
  return db().prepare("SELECT * FROM blog_posts ORDER BY createdAt DESC").all() as unknown as BlogPostRecord[];
}

export function getPostBySlug(slug: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE slug = ?").get(slug) as unknown as
    | BlogPostRecord
    | undefined;
}

export function getPostById(id: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE id = ?").get(id) as unknown as BlogPostRecord | undefined;
}

export function createPost(input: {
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl?: string;
  tags: string[];
  authorName: string;
  published: boolean;
}): BlogPostRecord {
  const id = newId();
  const now = nowIso();
  const slug = uniqueSlug(input.title);
  db()
    .prepare(
      `INSERT INTO blog_posts
        (id, slug, title, excerpt, body, coverImageUrl, tags, authorName, published, publishedAt, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      input.published ? now : null,
      now,
      now
    );
  return getPostById(id)!;
}

export function updatePost(
  id: string,
  input: {
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl?: string;
    tags: string[];
    authorName: string;
    published: boolean;
  }
) {
  const existing = getPostById(id);
  if (!existing) return;
  const slug = existing.title === input.title ? existing.slug : uniqueSlug(input.title, id);
  const publishedAt = input.published ? existing.publishedAt || nowIso() : null;
  db()
    .prepare(
      `UPDATE blog_posts SET slug = ?, title = ?, excerpt = ?, body = ?, coverImageUrl = ?, tags = ?, authorName = ?, published = ?, publishedAt = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      publishedAt,
      nowIso(),
      id
    );
}

export function deletePost(id: string) {
  db().prepare("DELETE FROM blog_posts WHERE id = ?").run(id);
}

// ---------- Impact stories ----------

export function listImpactStories(): ImpactStoryRecord[] {
  return db()
    .prepare("SELECT * FROM impact_stories ORDER BY sortOrder ASC, createdAt DESC")
    .all() as unknown as ImpactStoryRecord[];
}

export function getImpactStoryById(id: string): ImpactStoryRecord | undefined {
  return db().prepare("SELECT * FROM impact_stories WHERE id = ?").get(id) as unknown as
    | ImpactStoryRecord
    | undefined;
}

export function createImpactStory(input: {
  studentName: string;
  headline: string;
  story: string;
  photoUrl?: string;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: boolean;
  sortOrder?: number;
}): ImpactStoryRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO impact_stories
        (id, studentName, headline, story, photoUrl, destinationCountry, targetLevel, featured, sortOrder, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      nowIso()
    );
  return getImpactStoryById(id)!;
}

export function updateImpactStory(
  id: string,
  input: {
    studentName: string;
    headline: string;
    story: string;
    photoUrl?: string;
    destinationCountry: string;
    targetLevel: TargetLevel;
    featured: boolean;
    sortOrder?: number;
  }
) {
  db()
    .prepare(
      `UPDATE impact_stories SET studentName = ?, headline = ?, story = ?, photoUrl = ?, destinationCountry = ?, targetLevel = ?, featured = ?, sortOrder = ?
       WHERE id = ?`
    )
    .run(
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      id
    );
}

export function deleteImpactStory(id: string) {
  db().prepare("DELETE FROM impact_stories WHERE id = ?").run(id);
}

// ---------- Volunteer / donate / apply leads ----------

export function listLeads(): VolunteerLeadRecord[] {
  return db().prepare("SELECT * FROM volunteer_leads ORDER BY createdAt DESC").all() as unknown as VolunteerLeadRecord[];
}

export function createLead(input: {
  type: LeadType;
  name: string;
  email: string;
  phone?: string;
  message: string;
  areasOfInterest?: string[];
  availability?: string;
}) {
  db()
    .prepare(
      `INSERT INTO volunteer_leads (id, type, name, email, phone, message, areasOfInterest, availability, handled, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(
      newId(),
      input.type,
      input.name,
      input.email,
      input.phone ?? null,
      input.message,
      JSON.stringify(input.areasOfInterest ?? []),
      input.availability ?? "",
      nowIso()
    );
}

export function markLeadHandled(id: string, handled: boolean) {
  db().prepare("UPDATE volunteer_leads SET handled = ? WHERE id = ?").run(handled ? 1 : 0, id);
}


// ---------- Notifications ----------

export function createNotification(input: {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
}) {
  db()
    .prepare(
      `INSERT INTO notifications (id, userId, type, title, body, link, read, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), input.userId, input.type, input.title, input.body ?? "", input.link ?? null, nowIso());
}

/** Notify every admin at once - used for events any admin should see (new student, new lead). */
export function notifyAllAdmins(input: { type: NotificationType; title: string; body?: string; link?: string }) {
  const admins = db().prepare("SELECT id FROM users WHERE role = 'admin'").all() as unknown as { id: string }[];
  for (const admin of admins) {
    createNotification({ ...input, userId: admin.id });
  }
}

/** Full admin user records (id, email, name) - used to email every admin, not just notify in-app. */
export function listAdminUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users WHERE role = 'admin'").all() as unknown as UserRecord[];
}

export function listNotifications(userId: string, limit = 20): NotificationRecord[] {
  return db()
    .prepare("SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC LIMIT ?")
    .all(userId, limit) as unknown as NotificationRecord[];
}

export function countUnreadNotifications(userId: string): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND read = 0").get(userId) as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

export function markNotificationRead(id: string, userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE id = ? AND userId = ?").run(id, userId);
}

export function markAllNotificationsRead(userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE userId = ? AND read = 0").run(userId);
}

// ---------- Jobs ----------

export function createJob(input: {
  title: string;
  employer: string;
  country: string;
  city?: string;
  industry?: string;
  employmentType?: string;
  experienceRequired?: string;
  educationRequirement?: string;
  languageRequirement?: string;
  salary?: string;
  sponsorshipInfo?: string;
  applicationDeadline?: string | null;
  lastVerifiedDate?: string | null;
  source?: string;
  verificationStatus?: JobVerificationStatus;
  applicationUrl?: string;
  description?: string;
  published?: boolean;
}): JobRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO jobs
        (id, title, employer, country, city, industry, employmentType, experienceRequired, educationRequirement, languageRequirement, salary, sponsorshipInfo, applicationDeadline, lastVerifiedDate, source, verificationStatus, applicationUrl, description, published, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.title,
      input.employer,
      input.country,
      input.city ?? "",
      input.industry ?? "",
      input.employmentType ?? "",
      input.experienceRequired ?? "",
      input.educationRequirement ?? "",
      input.languageRequirement ?? "",
      input.salary ?? "",
      input.sponsorshipInfo ?? "",
      input.applicationDeadline ?? null,
      input.lastVerifiedDate ?? null,
      input.source ?? "",
      input.verificationStatus ?? "pending_verification",
      input.applicationUrl ?? "",
      input.description ?? "",
      input.published ? 1 : 0,
      now,
      now
    );
  return getJobById(id)!;
}

export function updateJob(
  id: string,
  input: Partial<Omit<JobRecord, "id" | "createdAt" | "updatedAt" | "published">> & { published?: boolean | number }
) {
  const current = getJobById(id);
  if (!current) return;
  const merged = {
    ...current,
    ...input,
    published: input.published === undefined ? current.published : input.published ? 1 : 0,
  };
  db()
    .prepare(
      `UPDATE jobs SET title = ?, employer = ?, country = ?, city = ?, industry = ?, employmentType = ?, experienceRequired = ?, educationRequirement = ?, languageRequirement = ?, salary = ?, sponsorshipInfo = ?, applicationDeadline = ?, lastVerifiedDate = ?, source = ?, verificationStatus = ?, applicationUrl = ?, description = ?, published = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      merged.title,
      merged.employer,
      merged.country,
      merged.city,
      merged.industry,
      merged.employmentType,
      merged.experienceRequired,
      merged.educationRequirement,
      merged.languageRequirement,
      merged.salary,
      merged.sponsorshipInfo,
      merged.applicationDeadline,
      merged.lastVerifiedDate,
      merged.source,
      merged.verificationStatus,
      merged.applicationUrl,
      merged.description,
      merged.published ? 1 : 0,
      nowIso(),
      id
    );
}

export function deleteJob(id: string) {
  db().prepare("DELETE FROM jobs WHERE id = ?").run(id);
}

export function getJobById(id: string): JobRecord | undefined {
  return db().prepare("SELECT * FROM jobs WHERE id = ?").get(id) as JobRecord | undefined;
}

/** All jobs, newest first - for the admin list (includes unpublished/expired). */
export function listAllJobs(): JobRecord[] {
  return db().prepare("SELECT * FROM jobs ORDER BY createdAt DESC").all() as unknown as JobRecord[];
}

/** Published, non-expired jobs only - for the public site. */
export function listPublishedJobs(): JobRecord[] {
  return db()
    .prepare("SELECT * FROM jobs WHERE published = 1 AND verificationStatus != 'expired' ORDER BY createdAt DESC")
    .all() as unknown as JobRecord[];
}

'@
[System.IO.File]::WriteAllText("src/lib/repo.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
$content = @'
import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
  scholarshipInterest: z.boolean(),
  currentEducationLevel: z.enum(["shs_graduate", "tertiary", "graduate", "other"]),
});

export const freeRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  schoolName: z.string().min(2, "Enter your school's name"),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
});

export const workVisaRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  profession: z.string().min(2, "Enter your profession or field"),
  currentOccupation: z.string().optional().default(""),
  yearsExperience: z.string().min(1, "Select your years of experience"),
  hasJobOffer: z.boolean(),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination country"),
});

export const setPasswordSchema = z
  .object({
    token: z.string().min(1),
    password: z.string().min(8, "Password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

export const loginSchema = z.object({
  email: z.string().email("Enter a valid email address"),
  password: z.string().min(1, "Enter your password"),
});

export const siteContentSchema = z.object({
  orgName: z.string().min(1),
  tagline: z.string().min(1),
  mission: z.string().min(1),
  vision: z.string().min(1),
  contactEmail: z.string().email(),
  contactPhone: z.string().optional().default(""),
  address: z.string().optional().default(""),
  donateInfo: z.string().optional().default(""),
  logoUrl: z.string().optional().default(""),
  heroImageUrl: z.string().optional().default(""),
  founderName: z.string().optional().default(""),
  founderTitle: z.string().optional().default(""),
  founderBio: z.string().optional().default(""),
  founderPhotoUrl: z.string().optional().default(""),
  undergradInfo: z.string().optional().default(""),
  mastersInfo: z.string().optional().default(""),
  phdInfo: z.string().optional().default(""),
  scholarshipsInfo: z.string().optional().default(""),
  workVisaInfo: z.string().optional().default(""),
  caretakingInfo: z.string().optional().default(""),
});

export const staffSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const boardMemberSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const noteSchema = z.object({
  text: z.string().optional().default(""),
});

export const createStaffUserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  username: z.string().min(3),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  tempPassword: z.string().min(8),
});

export const blogPostSchema = z.object({
  title: z.string().min(3, "Title is required"),
  excerpt: z.string().min(1, "Add a short excerpt for search results and previews"),
  body: z.string().min(1, "Post body cannot be empty"),
  coverImageUrl: z.string().optional().default(""),
  tags: z.array(z.string()).default([]),
  authorName: z.string().min(1, "Author name is required"),
  published: z.boolean(),
});

export const impactStorySchema = z.object({
  studentName: z.string().min(1, "Student name is required"),
  headline: z.string().min(1, "Headline is required"),
  story: z.string().min(1, "Story text is required"),
  photoUrl: z.string().optional().default(""),
  destinationCountry: z.string().min(1, "Destination is required"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  featured: z.boolean(),
});

export const leadSchema = z
  .object({
    type: z.enum(["volunteer", "donate", "apply_interest", "contact"]),
    name: z.string().min(2, "Enter your name"),
    email: z.string().email("Enter a valid email address"),
    phone: z.string().optional().default(""),
    message: z.string().optional().default(""),
    areasOfInterest: z.array(z.string()).optional().default([]),
    availability: z.string().optional().default(""),
  })
  .refine((data) => !["donate", "contact"].includes(data.type) || data.message.trim().length > 0, {
    message: "Please add a short message",
    path: ["message"],
  })
  .refine((data) => data.type !== "volunteer" || data.areasOfInterest.length > 0, {
    message: "Choose at least one area you'd like to help with",
    path: ["areasOfInterest"],
  });

export const adminEmailSchema = z.object({
  subject: z.string().min(1, "Add a subject line"),
  body: z.string().min(1, "Write a message"),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Enter your current password"),
    newPassword: z.string().min(8, "New password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "New passwords do not match",
    path: ["confirmPassword"],
  });

export const jobSchema = z.object({
  title: z.string().min(2, "Enter a job title"),
  employer: z.string().min(2, "Enter the employer name"),
  country: z.string().min(1, "Select a country"),
  city: z.string().optional().default(""),
  industry: z.string().optional().default(""),
  employmentType: z.string().optional().default(""),
  experienceRequired: z.string().optional().default(""),
  educationRequirement: z.string().optional().default(""),
  languageRequirement: z.string().optional().default(""),
  salary: z.string().optional().default(""),
  sponsorshipInfo: z.string().optional().default(""),
  applicationDeadline: z.string().optional().default(""),
  lastVerifiedDate: z.string().optional().default(""),
  source: z.string().optional().default(""),
  verificationStatus: z.enum(["verified", "employer_source", "government_source", "pending_verification", "expired"]),
  applicationUrl: z.string().optional().default(""),
  description: z.string().optional().default(""),
  published: z.boolean(),
});

'@
[System.IO.File]::WriteAllText("src/lib/validators.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/types" | Out-Null
$content = @'
export type Role = "admin" | "staff" | "student";

export type TargetLevel = "undergrad" | "masters" | "phd";

export type ApplicationStatus =
  | "new"
  | "documents_pending"
  | "in_review"
  | "submitted"
  | "scholarship_review"
  | "accepted"
  | "not_proceeding";

export const APPLICATION_STATUSES: { value: ApplicationStatus; label: string }[] = [
  { value: "new", label: "New" },
  { value: "documents_pending", label: "Documents pending" },
  { value: "in_review", label: "In review" },
  { value: "submitted", label: "Submitted" },
  { value: "scholarship_review", label: "Scholarship review" },
  { value: "accepted", label: "Accepted" },
  { value: "not_proceeding", label: "Not proceeding" },
];

export const TARGET_LEVELS: { value: TargetLevel; label: string }[] = [
  { value: "undergrad", label: "Undergraduate" },
  { value: "masters", label: "Master's" },
  { value: "phd", label: "PhD" },
];

export const TARGET_COUNTRIES = ["USA", "Canada", "UK", "Germany", "Other Europe", "Asia"];

export type CurrentEducationLevel = "shs_current" | "shs_graduate" | "tertiary" | "graduate" | "other";

export const CURRENT_EDUCATION_LEVELS: { value: CurrentEducationLevel; label: string }[] = [
  { value: "shs_graduate", label: "Completed Senior High School / awaiting results" },
  { value: "tertiary", label: "Currently in university / tertiary institution" },
  { value: "graduate", label: "Already completed a university degree" },
  { value: "other", label: "Other" },
];

export type ApplicationType = "standard" | "free_shs";

export interface DocumentItem {
  name: string;
  done: boolean;
  fileUrl?: string | null;
  uploadedAt?: string | null;
}

export interface UserRecord {
  id: string;
  username: string;
  email: string;
  passwordHash: string | null;
  role: Role;
  name: string;
  emailVerified: number;
  createdAt: string;
  updatedAt: string;
}

export interface StaffProfileRecord {
  id: string;
  userId: string | null;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export interface BoardMemberRecord {
  id: string;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export type ApplicationTrack = "university" | "work_visa";

export const YEARS_EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1-3 years",
  "3-5 years",
  "5-10 years",
  "10+ years",
];

export interface StudentRecord {
  id: string;
  code: string;
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string; // JSON-encoded string[]
  status: ApplicationStatus;
  assignedStaffId: string | null;
  documents: string; // JSON-encoded DocumentItem[]
  scholarshipInterest: number;
  currentEducationLevel: CurrentEducationLevel | "";
  schoolName: string;
  applicationType: ApplicationType;
  photoUrl: string | null;
  applicationTrack: ApplicationTrack;
  profession: string;
  currentOccupation: string;
  yearsExperience: string;
  hasJobOffer: number;
  createdAt: string;
  updatedAt: string;
}

export interface StudentNoteRecord {
  id: string;
  studentId: string;
  authorId: string;
  text: string;
  attachmentUrl: string | null;
  createdAt: string;
}

export interface SiteContentRecord {
  id: number;
  orgName: string;
  tagline: string;
  mission: string;
  vision: string;
  contactEmail: string;
  contactPhone: string;
  address: string;
  donateInfo: string;
  logoUrl: string | null;
  heroImageUrl: string | null;
  founderName: string;
  founderTitle: string;
  founderBio: string;
  founderPhotoUrl: string | null;
  undergradInfo: string;
  mastersInfo: string;
  phdInfo: string;
  scholarshipsInfo: string;
  workVisaInfo: string;
  caretakingInfo: string;
}

export interface BlogPostRecord {
  id: string;
  slug: string;
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl: string | null;
  tags: string; // JSON-encoded string[]
  authorName: string;
  published: number;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ImpactStoryRecord {
  id: string;
  studentName: string;
  headline: string;
  story: string;
  photoUrl: string | null;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: number;
  sortOrder: number;
  createdAt: string;
}

export type LeadType = "volunteer" | "donate" | "apply_interest" | "contact";

export interface VolunteerLeadRecord {
  id: string;
  type: LeadType;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  areasOfInterest: string; // JSON-encoded string[], only meaningful for type "volunteer"
  availability: string;
  handled: number;
  createdAt: string;
}

export const VOLUNTEER_AREAS = [
  "Essay review",
  "Mock interviews",
  "Mentoring a student",
  "Fundraising",
  "Event support",
  "Social media / content",
  "Other",
];

export interface SessionPayload {
  userId: string;
  role: Role;
  name: string;
}

export type NotificationType =
  | "message"
  | "document_uploaded"
  | "status_changed"
  | "student_assigned"
  | "new_student"
  | "new_lead"
  | "form_requested";

export interface NotificationRecord {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  link: string | null;
  read: number;
  createdAt: string;
}

export type JobVerificationStatus =
  | "verified"
  | "employer_source"
  | "government_source"
  | "pending_verification"
  | "expired";

export const JOB_VERIFICATION_LABELS: Record<JobVerificationStatus, string> = {
  verified: "Verified",
  employer_source: "Employer Source",
  government_source: "Government/Official Source",
  pending_verification: "Pending Verification",
  expired: "Expired",
};

export const JOB_COUNTRIES = ["USA", "Germany", "Other"];

export interface JobRecord {
  id: string;
  title: string;
  employer: string;
  country: string;
  city: string;
  industry: string;
  employmentType: string;
  experienceRequired: string;
  educationRequirement: string;
  languageRequirement: string;
  salary: string;
  sponsorshipInfo: string;
  applicationDeadline: string | null;
  lastVerifiedDate: string | null;
  source: string;
  verificationStatus: JobVerificationStatus;
  applicationUrl: string;
  description: string;
  published: number;
  createdAt: string;
  updatedAt: string;
}

'@
[System.IO.File]::WriteAllText("src/types/index.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
$content = @'
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth";
import { createJob, updateJob, deleteJob, getJobById } from "@/lib/repo";
import { jobSchema } from "@/lib/validators";
import type { JobVerificationStatus } from "@/types";

export type FormState = { error?: string; success?: string };

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  return session;
}

function parseJobForm(formData: FormData) {
  return jobSchema.safeParse({
    title: String(formData.get("title") || ""),
    employer: String(formData.get("employer") || ""),
    country: String(formData.get("country") || ""),
    city: String(formData.get("city") || ""),
    industry: String(formData.get("industry") || ""),
    employmentType: String(formData.get("employmentType") || ""),
    experienceRequired: String(formData.get("experienceRequired") || ""),
    educationRequirement: String(formData.get("educationRequirement") || ""),
    languageRequirement: String(formData.get("languageRequirement") || ""),
    salary: String(formData.get("salary") || ""),
    sponsorshipInfo: String(formData.get("sponsorshipInfo") || ""),
    applicationDeadline: String(formData.get("applicationDeadline") || ""),
    lastVerifiedDate: String(formData.get("lastVerifiedDate") || ""),
    source: String(formData.get("source") || ""),
    verificationStatus: String(formData.get("verificationStatus") || "pending_verification") as JobVerificationStatus,
    applicationUrl: String(formData.get("applicationUrl") || ""),
    description: String(formData.get("description") || ""),
    published: formData.get("published") === "on",
  });
}

export async function createJobAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = parseJobForm(formData);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  const job = createJob({
    ...parsed.data,
    applicationDeadline: parsed.data.applicationDeadline || null,
    lastVerifiedDate: parsed.data.lastVerifiedDate || null,
  });
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
  redirect(`/admin/jobs/${job.id}`);
}

export async function updateJobAction(id: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = parseJobForm(formData);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  updateJob(id, {
    ...parsed.data,
    applicationDeadline: parsed.data.applicationDeadline || null,
    lastVerifiedDate: parsed.data.lastVerifiedDate || null,
  });
  revalidatePath("/admin/jobs");
  revalidatePath(`/admin/jobs/${id}`);
  revalidatePath("/work-visa");
  return { success: "Job listing updated." };
}

export async function deleteJobAction(id: string): Promise<void> {
  await requireAdmin();
  deleteJob(id);
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
}

export async function toggleJobPublishedAction(formData: FormData) {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const job = getJobById(id);
  if (!job) return;
  updateJob(id, { published: job.published ? 0 : 1 });
  revalidatePath("/admin/jobs");
  revalidatePath("/work-visa");
}

'@
[System.IO.File]::WriteAllText("src/app/actions/jobs.ts", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/jobs/[id]" | Out-Null
$content = @'
import { notFound } from "next/navigation";
import { getJobById } from "@/lib/repo";
import { updateJobAction } from "@/app/actions/jobs";
import { JobForm } from "../job-form";

export const dynamic = "force-dynamic";

export default async function EditJobPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const job = getJobById(id);
  if (!job) notFound();

  const action = updateJobAction.bind(null, job.id);

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit job listing</h1>
      <JobForm job={job} action={action} />
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/jobs/[id]/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/jobs" | Out-Null
$content = @'
"use client";

import { useActionState } from "react";
import { JOB_COUNTRIES, JOB_VERIFICATION_LABELS, type JobRecord } from "@/types";
import type { FormState } from "@/app/actions/jobs";

export function JobForm({
  job,
  action,
}: {
  job?: JobRecord;
  action: (prevState: FormState, formData: FormData) => Promise<FormState>;
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Job title">
          <input name="title" defaultValue={job?.title} required className="input" placeholder="e.g. Registered Nurse" />
        </Field>
        <Field label="Employer">
          <input name="employer" defaultValue={job?.employer} required className="input" placeholder="e.g. Charite Berlin" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-3 gap-5">
        <Field label="Country">
          <select name="country" defaultValue={job?.country ?? "USA"} className="input">
            {JOB_COUNTRIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </Field>
        <Field label="City">
          <input name="city" defaultValue={job?.city} className="input" placeholder="e.g. Berlin" />
        </Field>
        <Field label="Industry">
          <input name="industry" defaultValue={job?.industry} className="input" placeholder="e.g. Healthcare" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Employment type">
          <input name="employmentType" defaultValue={job?.employmentType} className="input" placeholder="e.g. Full-time" />
        </Field>
        <Field label="Experience required">
          <input name="experienceRequired" defaultValue={job?.experienceRequired} className="input" placeholder="e.g. 2+ years" />
        </Field>
        <Field label="Education requirement">
          <input name="educationRequirement" defaultValue={job?.educationRequirement} className="input" placeholder="e.g. Bachelor's degree" />
        </Field>
        <Field label="Language requirement">
          <input name="languageRequirement" defaultValue={job?.languageRequirement} className="input" placeholder="e.g. English, German B2" />
        </Field>
        <Field label="Salary (only if publicly available)">
          <input name="salary" defaultValue={job?.salary} className="input" placeholder="Leave blank if not public" />
        </Field>
        <Field label="Sponsorship information">
          <input name="sponsorshipInfo" defaultValue={job?.sponsorshipInfo} className="input" placeholder="e.g. Verify eligibility" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Application deadline (optional)">
          <input type="date" name="applicationDeadline" defaultValue={job?.applicationDeadline ?? ""} className="input" />
        </Field>
        <Field label="Last verified date">
          <input type="date" name="lastVerifiedDate" defaultValue={job?.lastVerifiedDate ?? ""} className="input" />
        </Field>
      </div>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Source">
          <input name="source" defaultValue={job?.source} className="input" placeholder="e.g. Official employer careers page" />
        </Field>
        <Field label="Verification status">
          <select name="verificationStatus" defaultValue={job?.verificationStatus ?? "pending_verification"} className="input">
            {Object.entries(JOB_VERIFICATION_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <Field label="Application URL (the employer's real application page)">
        <input name="applicationUrl" type="url" defaultValue={job?.applicationUrl} className="input" placeholder="https://..." />
      </Field>

      <Field label="Description (optional)">
        <textarea name="description" defaultValue={job?.description} rows={5} className="input" />
      </Field>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="published" defaultChecked={job ? job.published === 1 : false} className="accent-teal" />
        Published (visible on the public Work Visa page)
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : job ? "Save changes" : "Add job"}
      </button>
    </form>
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

'@
[System.IO.File]::WriteAllText("src/app/admin/jobs/job-form.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/jobs/new" | Out-Null
$content = @'
import { createJobAction } from "@/app/actions/jobs";
import { JobForm } from "../job-form";

export default function NewJobPage() {
  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Add a job listing</h1>
      <JobForm action={createJobAction} />
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/jobs/new/page.tsx", $content, $Utf8NoBom)

New-Item -ItemType Directory -Force -Path "src/app/admin/jobs" | Out-Null
$content = @'
import Link from "next/link";
import { listAllJobs } from "@/lib/repo";
import { JOB_VERIFICATION_LABELS } from "@/types";
import { DeleteButton } from "@/components/delete-button";
import { deleteJobAction, toggleJobPublishedAction } from "@/app/actions/jobs";

export const dynamic = "force-dynamic";

export default function AdminJobsPage() {
  const jobs = listAllJobs();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Job listings</h1>
          <p className="text-ink/60">
            Real, verified international job opportunities shown on the Work Visa page. Never publish a
            listing you haven't personally verified.
          </p>
        </div>
        <Link href="/admin/jobs/new" className="btn-primary">
          + Add job
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {jobs.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No job listings yet.</p>}
        {jobs.map((j) => (
          <div key={j.id} className="p-4 flex items-center justify-between gap-4">
            <div>
              <p className="font-medium">
                {j.title} <span className="text-ink/50 font-normal">&middot; {j.employer}</span>
              </p>
              <p className="text-xs text-ink/50 mt-0.5">
                {j.country}
                {j.city ? ` \u00b7 ${j.city}` : ""} &middot; {JOB_VERIFICATION_LABELS[j.verificationStatus]}
                {j.published ? (
                  <span className="text-teal"> &middot; Published</span>
                ) : (
                  <span className="text-gold-deep"> &middot; Unpublished</span>
                )}
              </p>
            </div>
            <div className="flex items-center gap-4 text-sm shrink-0">
              <form action={toggleJobPublishedAction}>
                <input type="hidden" name="id" value={j.id} />
                <button type="submit" className="text-teal hover:underline">
                  {j.published ? "Unpublish" : "Publish"}
                </button>
              </form>
              <Link href={`/admin/jobs/${j.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={j.id} action={deleteJobAction} confirmLabel={`Delete "${j.title}" at ${j.employer}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/app/admin/jobs/page.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Add job listings database with admin CRUD (Phase 2a of work-visa platform)"
git push

Write-Host 'Done. Files written and pushed.'