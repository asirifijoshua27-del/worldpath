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
                        {s.destinationCountry} &middot; {s.targetLevel}
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

