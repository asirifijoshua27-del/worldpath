import { getSiteContent, listStaff, listBoardMembers } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AboutPage() {
  const content = getSiteContent();
  const staff = listStaff();
  const board = listBoardMembers();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">About us</p>
          <h1 className="font-display text-4xl mt-4 max-w-2xl">Who's behind {content.orgName}</h1>
          <p className="mt-6 text-lg text-ink/80 max-w-2xl">{content.mission}</p>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-teal font-medium mb-2">Day to day</p>
          <h2 className="font-display text-2xl mb-8">Staff directory</h2>
          {staff.length === 0 ? (
            <EmptyNote text="Staff profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {staff.map((s) => (
                <PersonCard key={s.id} name={s.name} title={s.title} bio={s.bio} photoUrl={s.photoUrl} variant="staff" />
              ))}
            </div>
          )}
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-2">Governance</p>
          <h2 className="font-display text-2xl mb-8">Board of Directors</h2>
          {board.length === 0 ? (
            <EmptyNote text="Board member profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {board.map((b) => (
                <PersonCard key={b.id} name={b.name} title={b.title} bio={b.bio} photoUrl={b.photoUrl} variant="board" />
              ))}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

function PersonCard({
  name,
  title,
  bio,
  photoUrl,
  variant,
}: {
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  variant: "staff" | "board";
}) {
  const isBoard = variant === "board";
  return (
    <div
      className={`rounded-xl p-6 border ${
        isBoard ? "border-gold-deep/30 bg-gold/5" : "border-line"
      }`}
    >
      <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden mb-4">
        {photoUrl ? (
          <PhotoLightbox src={photoUrl} alt={name} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full grid place-items-center">
            <span className="font-display text-2xl">{name.charAt(0)}</span>
          </div>
        )}
      </div>
      <h3 className="font-display text-lg">{name}</h3>
      <p className={`text-sm mb-2 ${isBoard ? "text-gold-deep" : "text-teal"}`}>
        {isBoard ? "Board &middot; " : ""}
        {title}
      </p>
      <p className="text-sm text-ink/70 leading-relaxed">{bio}</p>
    </div>
  );
}

function EmptyNote({ text }: { text: string }) {
  return <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">{text}</p>;
}

