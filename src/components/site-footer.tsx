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
