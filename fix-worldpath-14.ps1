# WorldPath Group - two SEO/search fixes:
# 1. Favicon was only 32x32 - too small for Google to reliably show it in
#    search results (needs 48x48 minimum). Bumped to 128x128.
# 2. Found remaining em-dash characters in page text and metadata
#    descriptions that were still showing up garbled (e.g. on Google's
#    Get Involved snippet) - replaced with plain hyphens everywhere
#    public-facing.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
// Google requires at least 48x48 to reliably show a favicon in search
// results at all (smaller sizes often just fall back to a generic globe
// icon) — 128x128 gives good headroom and stays sharp on high-DPI screens.
export const size = { width: 128, height: 128 };
export const contentType = "image/png";

async function logoDataUri(logoUrl: string | null): Promise<string | null> {
  if (!logoUrl || !logoUrl.startsWith("/api/uploads/")) return null;
  try {
    const filename = logoUrl.replace("/api/uploads/", "");
    const filePath = path.join(uploadDir(), filename);
    const buffer = await fs.readFile(filePath);
    const ext = path.extname(filename).slice(1);
    const mime = ext === "jpg" ? "jpeg" : ext;
    return `data:image/${mime};base64,${buffer.toString("base64")}`;
  } catch {
    return null;
  }
}

export default async function Icon() {
  const content = getSiteContent();
  const logo = await logoDataUri(content.logoUrl);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: logo ? "transparent" : "#0a2e3d",
          borderRadius: "50%",
        }}
      >
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} width={128} height={128} style={{ borderRadius: "50%", objectFit: "cover" }} />
        ) : (
          <span style={{ color: "#faf8f4", fontSize: 72 }}>W</span>
        )}
      </div>
    ),
    { ...size }
  );
}

'@ | Set-Content -LiteralPath "src/app/icon.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useRef, useState } from "react";

export function PhotoUploadField({
  existingUrl,
  name = "photo",
  hiddenFieldName = "existingPhotoUrl",
  shape = "circle",
}: {
  existingUrl?: string | null;
  name?: string;
  hiddenFieldName?: string;
  shape?: "circle" | "rect";
}) {
  const [preview, setPreview] = useState<string | null>(existingUrl || null);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  function handleFiles(files: FileList | null) {
    const file = files?.[0];
    if (!file) return;
    if (inputRef.current) {
      const dt = new DataTransfer();
      dt.items.add(file);
      inputRef.current.files = dt.files;
    }
    const reader = new FileReader();
    reader.onload = () => setPreview(reader.result as string);
    reader.readAsDataURL(file);
  }

  return (
    <div>
      <input type="hidden" name={hiddenFieldName} value={existingUrl ?? ""} />
      <div
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          handleFiles(e.dataTransfer.files);
        }}
        onClick={() => inputRef.current?.click()}
        className={`flex items-center gap-4 border-2 border-dashed rounded-xl p-4 cursor-pointer transition-colors ${
          dragging ? "border-teal bg-teal/5" : "border-line hover:border-teal/60"
        }`}
      >
        <div
          className={`bg-paper-dim border border-line grid place-items-center overflow-hidden shrink-0 ${
            shape === "circle" ? "w-24 h-24 rounded-full" : "w-32 h-20 rounded-lg"
          }`}
        >
          {preview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={preview} alt="Preview" className="w-full h-full object-cover" />
          ) : (
            <span className="text-xs text-ink/40">No photo</span>
          )}
        </div>
        <div className="text-sm">
          <p className="text-ink">
            <span className="text-teal">Click to upload</span> or drag and drop
          </p>
 <p className="text-ink/50 text-xs mt-0.5">JPG, PNG, WEBP, or GIF - up to 5MB</p>
        </div>
      </div>
      <input
        ref={inputRef}
        type="file"
        name={name}
        accept="image/jpeg,image/png,image/webp,image/gif"
        onChange={(e) => handleFiles(e.target.files)}
        className="hidden"
      />
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/components/photo-upload-field.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/undergraduate" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Undergraduate Applications | ${content.orgName}`,
    description: "Application support for undergraduate study abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function UndergraduatePage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Undergraduate"
      title="Undergraduate applications"
      body={content.undergradInfo}
 fallback="We help Ghanaian students build a competitive undergraduate application - from choosing the right universities to writing standout essays and finding scholarships to make it affordable."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/undergraduate/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/phd" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `PhD Applications | ${content.orgName}`,
    description: "Application support for PhD programs abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function PhdPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="PhD"
      title="PhD applications"
      body={content.phdInfo}
 fallback="We support Ghanaian students pursuing doctoral study abroad - from identifying the right advisors and programs to preparing research proposals and securing funding."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/phd/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/masters" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Master's Applications | ${content.orgName}`,
    description: "Application support for master's degrees abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function MastersPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Master's"
      title="Master's applications"
      body={content.mastersInfo}
 fallback="We support Ghanaian graduates applying for master's programs abroad - from selecting programs aligned with your career goals to strengthening your statement of purpose and finding funding."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/masters/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/scholarships" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Scholarships | ${content.orgName}`,
    description: "Scholarship and financial aid support for Ghanaian students applying to study abroad.",
  };
}

export default function ScholarshipsPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Funding"
      title="Scholarships & financial aid"
      body={content.scholarshipsInfo}
 fallback="We help you find and apply for merit-based and need-based scholarships and financial aid - especially at US universities, where most funding decisions are made as part of the admissions process itself."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/scholarships/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { createLead, markLeadHandled } from "@/lib/repo";
import { leadSchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

export async function submitLeadAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const parsed = leadSchema.safeParse({
    type: String(formData.get("type") || "volunteer"),
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    message: String(formData.get("message") || ""),
    areasOfInterest: formData.getAll("areasOfInterest").map(String),
    availability: String(formData.get("availability") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  createLead(parsed.data);
 return { success: "Thanks - we'll be in touch soon." };
}

export async function markLeadHandledAction(formData: FormData) {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  const id = String(formData.get("id") || "");
  const handled = formData.get("handled") === "true";
  markLeadHandled(id, handled);
  revalidatePath("/admin/leads");
}

'@ | Set-Content -LiteralPath "src/app/actions/leads.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/blog" | Out-Null
@'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listPublishedPosts } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Blog | ${content.orgName}`,
    description: "Student success stories and guides to applying for university and scholarships abroad.",
  };
}

export default function BlogIndexPage() {
  const content = getSiteContent();
  const posts = listPublishedPosts();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.25em] text-xs text-gold-deep font-medium">Blog</p>
          <h1 className="font-display text-4xl sm:text-5xl mt-5">Guides & stories</h1>
          <p className="mt-6 text-lg text-ink/70 max-w-xl">
            Application guides, scholarship tips, and stories from students on their way abroad.
          </p>
        </section>

        <section className="mx-auto max-w-5xl px-6 pb-20">
          {posts.length === 0 ? (
            <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
 No posts published yet - check back soon.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-8">
              {posts.map((p) => {
                const tags = JSON.parse(p.tags) as string[];
                return (
                  <Link
                    key={p.id}
                    href={`/blog/${p.slug}`}
                    className="border border-line rounded-xl overflow-hidden hover:border-gold-deep/60 hover:shadow-sm transition-all flex flex-col"
                  >
                    {p.coverImageUrl && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={p.coverImageUrl} alt={p.title} className="w-full h-40 object-cover" />
                    )}
                    <div className="p-6 flex-1 flex flex-col">
                      {tags.length > 0 && (
                        <p className="text-xs uppercase tracking-wide text-gold-deep mb-2">{tags[0]}</p>
                      )}
                      <h2 className="font-display text-xl mb-2">{p.title}</h2>
                      <p className="text-sm text-ink/70 leading-relaxed flex-1">{p.excerpt}</p>
                      <p className="text-xs text-ink/40 mt-4">
                        {p.publishedAt ? new Date(p.publishedAt).toLocaleDateString() : ""} · {p.authorName}
                      </p>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/blog/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
import Link from "next/link";
import { getSiteContent, listImpactStories } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PathRoute } from "@/components/path-route";
import { ArrowRight } from "@/components/arrow-right";

export const dynamic = "force-dynamic";

const CREDIBILITY_POINTS = [
  "One-on-one mentoring",
  "Scholarship-focused applications",
  "Student-centered support",
  "International study pathways",
];

const WHAT_STUDENTS_RECEIVE = [
  {
    title: "A tailored university shortlist",
 body: "Schools matched to your grades, goals, and budget - not a generic list.",
  },
  {
    title: "Personal statement & essay guidance",
    body: "One-on-one feedback to help your application sound like you, at your best.",
  },
  {
    title: "Scholarship & financial-aid search",
    body: "We help you find and apply for merit-based and need-based aid, especially in the US.",
  },
  {
    title: "Document review & tracking",
 body: "Your own portal to track every document and every stage - always up to date.",
  },
  {
    title: "Interview preparation",
    body: "Practice and coaching where an admissions or scholarship interview is required.",
  },
];

const HOW_IT_WORKS = [
  { title: "Apply online", body: "Create your account and tell us about your goals." },
  { title: "Meet an advisor", body: "We match you with a counselor to plan your path." },
 { title: "Prepare documents", body: "Essays, transcripts, and recommendations - reviewed together." },
  { title: "Submit applications", body: "We help you apply to universities and scholarships on time." },
  { title: "Track results", body: "Follow every stage from your own student portal." },
];

export default function HomePage() {
  const content = getSiteContent();
  const testimonial = listImpactStories().find((s) => s.featured === 1);

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        {/* Hero — full-bleed navy, IvyWise-style */}
        <section
          className="relative bg-navy text-paper overflow-hidden bg-cover bg-center"
          style={content.heroImageUrl ? { backgroundImage: `url(${content.heroImageUrl})` } : undefined}
        >
          {content.heroImageUrl && <div className="absolute inset-0 bg-navy/75" />}
          <div
            className="absolute inset-0 opacity-40"
            style={{
              background:
                "radial-gradient(ellipse 90% 60% at 50% -10%, rgba(15,110,140,0.55), transparent 60%)",
            }}
          />
          <div className="relative mx-auto max-w-5xl px-6 pt-24 pb-20 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">
              {content.orgName}
            </p>
            <h1 className="font-display text-4xl sm:text-6xl leading-[1.08] mt-5">
              Talent should decide who gets in.
              <br className="hidden sm:block" /> Not a bank balance.
            </h1>
            <p className="mt-6 text-lg text-paper/75 max-w-xl mx-auto">{content.tagline}</p>
            <div className="mt-9 flex flex-wrap justify-center gap-4">
              <Link
                href="/register"
                className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors"
              >
                Get application support
              </Link>
              <Link
                href="/about"
                className="rounded-full border border-paper/30 px-7 py-3 hover:border-paper/70 transition-colors"
              >
                Meet the team
              </Link>
            </div>
            <div className="mt-4">
              <PathRoute />
            </div>
          </div>
        </section>

        {/* Credibility strip — what we offer, not raw headcounts */}
        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-6 text-center">
            {CREDIBILITY_POINTS.map((point) => (
              <div key={point} className="flex flex-col items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-gold-deep" />
                <p className="text-sm font-medium">{point}</p>
              </div>
            ))}
          </div>
          <div className="text-center pb-8">
            <Link href="/impact" className="text-sm text-teal hover:underline">
              See our impact & student stories
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* What students receive */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Our services</p>
          <h2 className="font-display text-3xl mb-10">What students receive</h2>
          <div className="grid sm:grid-cols-2 gap-x-10 gap-y-8">
            {WHAT_STUDENTS_RECEIVE.map((item) => (
              <div key={item.title} className="flex gap-4">
                <span className="w-6 h-6 rounded-full bg-teal/10 text-teal grid place-items-center shrink-0 mt-0.5 text-xs font-medium">
                  ✓
                </span>
                <div>
                  <h3 className="font-medium mb-1">{item.title}</h3>
                  <p className="text-sm text-ink/70 leading-relaxed">{item.body}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">The process</p>
          <h2 className="font-display text-3xl mb-10">How it works</h2>
          <div className="grid sm:grid-cols-5 gap-6">
            {HOW_IT_WORKS.map((step, i) => (
              <div key={step.title}>
                <span className="font-display text-2xl text-gold-deep">{i + 1}</span>
                <h3 className="font-medium mt-2 mb-1">{step.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed">{step.body}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Mission */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Mission</p>
              <h2 className="font-display text-2xl mb-3">Why we exist</h2>
              <p className="text-ink/80 leading-relaxed">{content.mission}</p>
            </div>
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Vision</p>
              <h2 className="font-display text-2xl mb-3">Where we're headed</h2>
              <p className="text-ink/80 leading-relaxed">{content.vision}</p>
            </div>
          </div>
        </section>

        {/* Founder */}
        {content.founderName && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-6 text-center sm:text-left">
              Leadership
            </p>
            <div className="flex flex-col sm:flex-row items-center sm:items-start gap-8 text-center sm:text-left">
              <div className="w-32 h-32 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
                {content.founderPhotoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={content.founderPhotoUrl} alt={content.founderName} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full grid place-items-center text-3xl text-ink/30 font-display">
                    {content.founderName.charAt(0)}
                  </div>
                )}
              </div>
              <div>
                <h2 className="font-display text-2xl mb-1">{content.founderName}</h2>
                <p className="text-teal text-sm font-medium mb-4">{content.founderTitle}</p>
                <p className="text-ink/80 leading-relaxed max-w-xl">{content.founderBio}</p>
              </div>
            </div>
          </section>
        )}

        {/* Testimonial — only shown once a real, permitted story is marked featured in admin */}
        {testimonial && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <div className="rounded-2xl border border-gold-deep/30 bg-gold/5 px-8 py-10 sm:px-12 text-center">
              <p className="font-display text-2xl sm:text-3xl leading-snug text-ink mb-6">
                &ldquo;{testimonial.story}&rdquo;
              </p>
              <p className="text-sm font-medium">{testimonial.studentName}</p>
              <p className="text-xs text-ink/50 uppercase tracking-wide mt-1">
                {testimonial.destinationCountry}
              </p>
            </div>
          </section>
        )}

        {/* Caretaking foundation — short summary, full story lives on its own page */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14">
            <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-3">
              Beyond admissions
            </p>
            <h2 className="font-display text-2xl mb-3">About the Foundation</h2>
            <p className="text-paper/80 max-w-2xl leading-relaxed mb-6">
              WorldPath Caretaking Foundation is the nonprofit organization behind WorldPath Group,
              supporting education, mentorship, healthcare outreach, and community development across
              Ghana.
            </p>
            <Link
              href="/foundation"
              className="text-sm text-paper underline hover:text-teal transition-colors"
            >
              Learn more about the Foundation
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* Blog teaser */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="flex items-center justify-between mb-3">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">From the blog</p>
            <Link href="/blog" className="text-sm text-teal hover:underline">
              All posts
              <ArrowRight />
            </Link>
          </div>
          <h2 className="font-display text-2xl mb-3">Guides for applying abroad</h2>
          <p className="text-ink/70 max-w-2xl">
            Scholarship tips, application walkthroughs, and stories from students on their way abroad.
          </p>
        </section>

        {/* Free partnership note + CTA */}
        <section className="mx-auto max-w-6xl px-6 py-16">
          <div className="grid sm:grid-cols-2 gap-10 items-center">
            <div>
              <h2 className="font-display text-2xl mb-3">Free through Wesley Senior High School</h2>
              <p className="text-ink/80 leading-relaxed">
                Through our partnership with Wesley Senior High School, application assistance is
                provided free of charge to eligible students.
              </p>
            </div>
            <div className="sm:text-right">
              <Link href="/register/free" className="btn-primary inline-block">
                Apply for WorldPath guidance
              </Link>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/get-involved" | Out-Null
@'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { LeadForm } from "@/components/lead-form";
import { VolunteerApplicationForm } from "@/components/volunteer-application-form";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Get Involved | ${content.orgName}`,
 description: "Donate, volunteer, or apply - ways to get involved with WorldPath Group.",
  };
}

export default function GetInvolvedPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 pt-16 pb-8 text-center">
          <p className="uppercase tracking-[0.25em] text-xs text-gold-deep font-medium">Get involved</p>
          <h1 className="font-display text-4xl sm:text-5xl mt-5">Three ways to help open a door</h1>
          <p className="mt-6 text-lg text-ink/70 max-w-xl mx-auto">
 Donate, volunteer your time and expertise, or - if you're a student - apply for support.
          </p>
        </section>

        {/* Apply */}
        <section id="apply" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-2">For students</p>
              <h2 className="font-display text-2xl mb-2">Apply for application support</h2>
              <p className="text-paper/75 max-w-md">
                Free through our partnership with Wesley Senior High School, and open to other talented
                students in need across Ghana.
              </p>
            </div>
            <Link href="/register" className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Start your application
            </Link>
          </div>
        </section>

        {/* Donate */}
        <section id="donate" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Donate</p>
          <h2 className="font-display text-3xl mb-6">Fund a student's application</h2>
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <p className="text-ink/70 leading-relaxed whitespace-pre-line">
                {content.donateInfo || "Contact us to arrange a donation."}
              </p>
              <p className="text-sm text-ink/50 mt-4">
                Questions? Email{" "}
                <a href={`mailto:${content.contactEmail}`} className="text-teal hover:underline">
                  {content.contactEmail}
                </a>
                .
              </p>
            </div>
            <div>
              <p className="text-sm font-medium mb-3">Or let us know you're planning to give:</p>
              <LeadForm
                type="donate"
                messagePlaceholder="How would you like to support WorldPath Group?"
                submitLabel="Send"
              />
            </div>
          </div>
        </section>

        {/* Volunteer */}
        <section id="volunteer" className="mx-auto max-w-4xl px-6 py-14 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Volunteer</p>
          <h2 className="font-display text-3xl mb-3">Join WorldPath Group as a volunteer</h2>
          <p className="text-ink/70 max-w-2xl mb-8">
            We're always looking for essay reviewers, mock interviewers, and counselors who've been
            through the process themselves.
          </p>
          <div className="max-w-xl">
            <VolunteerApplicationForm />
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/get-involved/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/foundation" | Out-Null
@'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `WorldPath Caretaking Foundation | ${content.orgName}`,
    description:
      "The nonprofit organization behind WorldPath Group, supporting education, mentorship, healthcare outreach, and community development across Ghana.",
  };
}

export default function FoundationPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Beyond admissions</p>
          <h1 className="font-display text-4xl mt-4 mb-8">WorldPath Caretaking Foundation</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">
            {content.caretakingInfo ||
 "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities - because a student's wellbeing at home is part of their path to university too."}
          </p>

          <div className="mt-12 pt-8 border-t border-line">
            <Link href="/get-involved" className="btn-primary inline-block">
              See how you can help
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter
        orgName={content.orgName}
        contactEmail={content.contactEmail}
        contactPhone={content.contactPhone}
        address={content.address}
      />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/foundation/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
@'
import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";
import { DocumentUploadRow } from "./document-upload-row";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { studentAddNoteAction } from "@/app/actions/student";

export const dynamic = "force-dynamic";

export default async function StudentHomePage() {
  const session = await getSession();
  const student = session ? getStudentByUserId(session.userId) : undefined;

  if (!student) {
    return <p className="text-ink/60">We couldn't find your application record. Please contact WorldPath Group.</p>;
  }

  const staff = student.assignedStaffId ? getStaffById(student.assignedStaffId) : undefined;
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const completedDocs = documents.filter((d) => d.done).length;

  return (
    <div>
      <div className="flex items-center gap-4 mb-3">
        <div className="w-14 h-14 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={student.photoUrl} alt={session?.name || ""} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-ink/40">{session?.name?.charAt(0) ?? "?"}</div>
          )}
        </div>
        <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block">
          {student.code}
        </p>
      </div>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
 {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet - one will be soon."}
      </p>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Application status</p>
          <p className="font-display text-xl text-gold-deep">{statusLabel}</p>
        </div>
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Targeting</p>
          <p className="capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      <div className="mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display text-xl">Document checklist</h2>
          <span className="text-sm text-ink/50">
            {completedDocs}/{documents.length} complete
          </span>
        </div>
        <p className="text-xs text-ink/50 mb-3">
          Upload a photo or PDF of each document. Uploading automatically marks it complete.
        </p>
        <ul className="space-y-2">
          {documents.map((doc, index) => (
            <DocumentUploadRow key={doc.name} doc={doc} index={index} />
          ))}
        </ul>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Messages with your counselor</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="student"
          />
        </div>
        <MessageForm action={studentAddNoteAction} placeholder="Send a message to your counselor..." />
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/student/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/impact" | Out-Null
@'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent, listStudents, listImpactStories, listStaff } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Our Impact | ${content.orgName}`,
    description:
      "Real numbers and real student stories from WorldPath Group's work helping Ghanaian students reach university and scholarships abroad.",
  };
}

export default function ImpactPage() {
  const content = getSiteContent();
  const studentCount = listStudents().length;
  const staffCount = listStaff().length;
  const stories = listImpactStories();
  const featured = stories.filter((s) => s.featured === 1);
  const rest = stories.filter((s) => s.featured !== 1);
  const ordered = [...featured, ...rest];

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="bg-navy text-paper">
          <div className="mx-auto max-w-5xl px-6 pt-20 pb-16 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">Our impact</p>
            <h1 className="font-display text-4xl sm:text-5xl mt-5">Real students. Real universities.</h1>
            <p className="mt-6 text-lg text-paper/75 max-w-xl mx-auto">
 Every number here reflects a student who is currently in our program right now - not a
              marketing estimate.
            </p>
          </div>
        </section>

        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-8 text-center">
            <Stat value={studentCount} label="Students currently in the program" />
            <Stat value={staffCount} label="Counselors working with them" />
            <Stat value="5" label="Study destinations we cover" />
            <Stat value="Free" label="Application help via Wesley SHS" />
          </div>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Student stories</p>
          <h2 className="font-display text-3xl mb-10">In their own words</h2>

          {ordered.length === 0 ? (
            <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">
              Student stories will appear here as they're added from the admin portal.
            </p>
          ) : (
            <div className="grid sm:grid-cols-2 gap-8">
              {ordered.map((s) => (
                <article key={s.id} className="border border-line rounded-xl p-6">
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-12 h-12 rounded-full bg-paper-dim border border-line grid place-items-center overflow-hidden shrink-0">
                      {s.photoUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={s.photoUrl} alt={s.studentName} className="w-full h-full object-cover" />
                      ) : (
                        <span className="font-display">{s.studentName.charAt(0)}</span>
                      )}
                    </div>
                    <div>
                      <p className="font-medium">{s.studentName}</p>
                      <p className="text-xs text-gold-deep uppercase tracking-wide">
                        {s.destinationCountry} · {s.targetLevel}
                      </p>
                    </div>
                  </div>
                  <h3 className="font-display text-lg mb-2">{s.headline}</h3>
                  <p className="text-sm text-ink/70 leading-relaxed">{s.story}</p>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-2xl mb-2">Help us reach more students</h2>
              <p className="text-paper/75 max-w-lg">
                Every counselor, every scholarship search, every application costs time and money we
                raise from people who believe in this work.
              </p>
            </div>
            <Link href="/get-involved" className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Get involved
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

function Stat({ value, label }: { value: string | number; label: string }) {
  return (
    <div>
      <p className="font-display text-3xl sm:text-4xl text-gold-deep">{value}</p>
      <p className="text-xs sm:text-sm text-ink/60 mt-1">{label}</p>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/impact/page.tsx" -Encoding utf8

git add -A
git commit -m "Fix favicon size for Google search results, remove remaining garbled em-dash characters"
git push

Write-Host 'Done. Files written and pushed.'