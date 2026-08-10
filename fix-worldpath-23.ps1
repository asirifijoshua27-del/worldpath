# WorldPath Group - full redesign of /work-visa into an International
# Careers & Work Visa Support page (Phase 1 of the spec: page content,
# trust/scam sections, FAQ, destination cards, process, footer). The
# job-listings database with admin CRUD and per-job application tracking
# (spec sections 5, 7-9, 17) is a separate, larger build - not in this batch.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'
[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

New-Item -ItemType Directory -Force -Path "src/app/work-visa" | Out-Null
$content = @'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
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

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
$content = @'
import Link from "next/link";

// Displays a Ghana local number (0XXXXXXXXX) in international format
// (+233 XX XXX XXXX) without changing the underlying value stored in admin.
// Leaves anything that doesn't match the expected shape untouched, since
// the field can hold multiple numbers separated by "/".
function toInternationalGhana(phone: string): string {
  return phone
    .split("/")
    .map((raw) => {
      const digits = raw.trim().replace(/[^\d]/g, "");
      if (digits.length === 10 && digits.startsWith("0")) {
        const n = digits.slice(1);
        return `+233 ${n.slice(0, 2)} ${n.slice(2, 5)} ${n.slice(5)}`;
      }
      return raw.trim();
    })
    .join(" / ");
}

export function SiteFooter({
  orgName,
  contactEmail,
  contactPhone,
  address,
}: {
  orgName: string;
  contactEmail: string;
  contactPhone?: string;
  address: string;
}) {
  return (
    <footer className="border-t border-line mt-24">
      <div className="mx-auto max-w-6xl px-6 py-14 grid sm:grid-cols-4 gap-10 text-sm">
        <div className="sm:col-span-1">
          <p className="font-display text-base mb-2">{orgName}</p>
          <p className="text-ink/60 leading-relaxed">
            A project of{" "}
            <Link href="/foundation" className="hover:text-teal transition-colors underline">
              WorldPath Caretaking Foundation
            </Link>
            .
          </p>
        </div>

        <FooterColumn
          title="Programs"
          links={[
            { href: "/programs/undergraduate", label: "Undergraduate" },
            { href: "/programs/masters", label: "Master's" },
            { href: "/programs/phd", label: "PhD" },
            { href: "/scholarships", label: "Scholarships" },
          ]}
        />

        <FooterColumn
          title="International Careers"
          links={[
            { href: "/work-visa", label: "International Careers" },
            { href: "/work-visa#opportunities", label: "USA Opportunities" },
            { href: "/work-visa#opportunities", label: "Germany Opportunities" },
            { href: "/work-visa", label: "Work Visa Guidance" },
            { href: "/register/work-visa", label: "Applicant Assessment" },
            { href: "/work-visa#scam-awareness", label: "Scam Awareness" },
          ]}
        />

        <FooterColumn
          title="Organization"
          links={[
            { href: "/about", label: "About WorldPath" },
            { href: "/impact", label: "Impact" },
            { href: "/blog", label: "Blog" },
            { href: "/get-involved", label: "Get Involved" },
          ]}
        />
      </div>

      <div className="border-t border-line">
        <div className="mx-auto max-w-6xl px-6 py-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-sm">
          <div className="text-ink/60 space-y-0.5">
            {contactEmail && <p>{contactEmail}</p>}
            {contactPhone && <p>{toInternationalGhana(contactPhone)}</p>}
            {address && <p className="whitespace-pre-line">{address}</p>}
          </div>
          <Link href="/contact" className="text-teal hover:underline shrink-0">
            Contact page
          </Link>
        </div>
      </div>

      <div className="border-t border-line">
        <p className="mx-auto max-w-6xl px-6 py-5 text-xs text-ink/50">
          &copy; {new Date().getFullYear()} {orgName}. All rights reserved.
        </p>
      </div>
    </footer>
  );
}

function FooterColumn({ title, links }: { title: string; links: { href: string; label: string }[] }) {
  return (
    <div>
      <p className="font-medium mb-3">{title}</p>
      <ul className="space-y-1.5">
        {links.map((l) => (
          <li key={l.href + l.label}>
            <Link href={l.href} className="text-ink/60 hover:text-teal transition-colors">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

'@
[System.IO.File]::WriteAllText("src/components/site-footer.tsx", $content, $Utf8NoBom)

git add -A
git commit -m "Redesign work-visa page into International Careers & Work Visa Support platform"
git push

Write-Host 'Done. Files written and pushed.'