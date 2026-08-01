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
      <div className="mx-auto max-w-6xl px-6 py-10 flex flex-col sm:flex-row justify-between gap-6 text-sm text-ink/70">
        <p>
          &copy; {new Date().getFullYear()} {orgName}. A project of{" "}
          <Link href="/foundation" className="hover:text-teal transition-colors underline">
            WorldPath Caretaking Foundation
          </Link>
          .
        </p>
        <div className="flex flex-col sm:items-end gap-0.5">
          {contactEmail && <span>{contactEmail}</span>}
          {contactPhone && <span>{contactPhone}</span>}
          {address && <span className="whitespace-pre-line sm:text-right">{address}</span>}
        </div>
      </div>
    </footer>
  );
}

