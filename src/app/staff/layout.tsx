import { getSession } from "@/lib/auth";
import { PortalNav } from "@/components/portal-nav";

const LINKS = [{ href: "/staff", label: "My students" }];

export default async function StaffLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <>
      <PortalNav role="staff" name={session?.name || "Staff"} links={LINKS} />
      <main className="flex-1 mx-auto max-w-6xl w-full px-6 py-10">{children}</main>
    </>
  );
}
