import Link from "next/link";

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
          title="Organization"
          links={[
            { href: "/about", label: "About WorldPath" },
            { href: "/impact", label: "Impact" },
            { href: "/blog", label: "Blog" },
            { href: "/get-involved", label: "Get Involved" },
          ]}
        />

        <div>
          <p className="font-medium mb-3">Contact</p>
          <div className="space-y-1 text-ink/60">
            {contactEmail && <p>{contactEmail}</p>}
            {contactPhone && <p>{contactPhone}</p>}
            {address && <p className="whitespace-pre-line">{address}</p>}
          </div>
          <Link href="/contact" className="inline-block mt-2 text-teal hover:underline">
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
          <li key={l.href}>
            <Link href={l.href} className="text-ink/60 hover:text-teal transition-colors">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

