import { listLeads } from "@/lib/repo";
import { HandledToggle } from "./handled-toggle";

export const dynamic = "force-dynamic";

const TYPE_LABEL: Record<string, string> = {
  volunteer: "Volunteer",
  donate: "Donate inquiry",
  apply_interest: "Apply interest",
  contact: "Contact form",
};

export default function AdminLeadsPage() {
  const leads = listLeads();
  const open = leads.filter((l) => !l.handled);

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Leads</h1>
      <p className="text-ink/60 mb-8">
        Volunteer and donation inquiries submitted from the Get Involved page. {open.length} awaiting a reply.
      </p>

      <div className="divide-y divide-line border border-line rounded-xl">
        {leads.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No inquiries yet.</p>}
        {leads.map((l) => {
          const areas = l.areasOfInterest ? (JSON.parse(l.areasOfInterest) as string[]) : [];
          return (
            <div key={l.id} className={`p-4 ${l.handled ? "opacity-60" : ""}`}>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium">
                    {l.name} <span className="text-xs uppercase text-gold-deep ml-2">{TYPE_LABEL[l.type] ?? l.type}</span>
                  </p>
                  <p className="text-sm text-ink/60">
                    {l.email}
                    {l.phone ? ` Ã‚Â· ${l.phone}` : ""}
                  </p>
                  {areas.length > 0 && (
                    <p className="text-sm text-teal mt-2">{areas.join(" Ã‚Â· ")}</p>
                  )}
                  {l.availability && <p className="text-sm text-ink/60 mt-1">Availability: {l.availability}</p>}
                  {l.message && <p className="text-sm text-ink/80 mt-2 max-w-xl">{l.message}</p>}
                  <p className="text-xs text-ink/40 mt-2">{new Date(l.createdAt).toLocaleString()}</p>
                </div>
                <HandledToggle id={l.id} handled={l.handled === 1} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

