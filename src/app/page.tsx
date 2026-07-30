import Link from "next/link";
import { getSiteContent, listStudents, listStaff } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PathRoute } from "@/components/path-route";

export const dynamic = "force-dynamic";

export default function HomePage() {
  const content = getSiteContent();
  const studentCount = listStudents().length;
  const staffCount = listStaff().length;

  return (
    <>
      <SiteHeader orgName={content.orgName} />
      <main className="flex-1">
        {/* Hero — full-bleed navy, IvyWise-style */}
        <section className="relative bg-navy text-paper overflow-hidden">
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
                Start your application
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

        {/* Stats strip */}
        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-8 text-center">
            <Stat value={studentCount} label="Students in the program" />
            <Stat value={staffCount} label="Counselors on staff" />
            <Stat value="5" label="Study destinations" />
            <Stat value="Free" label="Via Wesley Senior High School" />
          </div>
          <div className="text-center pb-8">
            <Link href="/impact" className="text-sm text-teal hover:underline">
              See our full impact & student stories →
            </Link>
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

        {/* Services */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Our services</p>
          <h2 className="font-display text-3xl mb-10">How we help</h2>
          <div className="grid sm:grid-cols-3 gap-6">
            <ServiceCard
              n="01"
              title="Application guidance"
              body="One-on-one support building a competitive undergraduate, master's, or PhD application — from school shortlists to essays."
            />
            <ServiceCard
              n="02"
              title="Scholarship search"
              body="We help you find and apply for merit-based and need-based scholarships and financial aid, especially across US universities."
            />
            <ServiceCard
              n="03"
              title="Document & status tracking"
              body="Your own portal to track every document, every stage, and every note from your counselor — always up to date."
            />
          </div>
        </section>

        {/* Caretaking foundation */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14">
            <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-3">
              Beyond admissions
            </p>
            <h2 className="font-display text-2xl mb-3">WorldPath Caretaking Foundation</h2>
            <p className="text-paper/80 max-w-2xl leading-relaxed mb-6">
              Beyond university placement, our parent foundation supports caretaking homes with food
              and daily necessities on a quarterly cycle — because a student's wellbeing at home is
              part of their path to university too.
            </p>
            <Link href="/get-involved" className="text-sm text-paper underline hover:text-teal transition-colors">
              See how you can help →
            </Link>
          </div>
        </section>

        {/* Blog teaser */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="flex items-center justify-between mb-3">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">From the blog</p>
            <Link href="/blog" className="text-sm text-teal hover:underline">
              All posts →
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
              <Link href="/register" className="btn-primary inline-block">
                Apply now
              </Link>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} address={content.address} />
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

function ServiceCard({ n, title, body }: { n: string; title: string; body: string }) {
  return (
    <div className="border border-line rounded-xl p-6 hover:border-gold-deep/60 hover:shadow-sm transition-all">
      <p className="font-display text-sm text-gold-deep mb-3">{n}</p>
      <h3 className="font-display text-lg mb-2">{title}</h3>
      <p className="text-sm text-ink/70 leading-relaxed">{body}</p>
    </div>
  );
}
