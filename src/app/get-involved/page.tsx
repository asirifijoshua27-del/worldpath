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

