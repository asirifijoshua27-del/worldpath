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
        {/* Hero â€” full-bleed navy, IvyWise-style */}
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

        {/* Credibility strip â€” what we offer, not raw headcounts */}
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
                  âœ“
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

        {/* Testimonial â€” only shown once a real, permitted story is marked featured in admin */}
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

        {/* Caretaking foundation â€” short summary, full story lives on its own page */}
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

