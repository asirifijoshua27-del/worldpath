export function SiteFooter({
  orgName,
  contactEmail,
  address,
}: {
  orgName: string;
  contactEmail: string;
  address: string;
}) {
  return (
    <footer className="border-t border-line mt-24">
      <div className="mx-auto max-w-6xl px-6 py-10 flex flex-col sm:flex-row justify-between gap-4 text-sm text-ink/70">
        <p>
          &copy; {new Date().getFullYear()} {orgName}. A project of WorldPath Caretaking Foundation.
        </p>
        <p className="flex flex-col sm:items-end gap-0.5">
          {contactEmail && <span>{contactEmail}</span>}
          {address && <span>{address}</span>}
        </p>
      </div>
    </footer>
  );
}
