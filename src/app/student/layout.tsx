import { getSession } from "@/lib/auth";
import { PortalNav } from "@/components/portal-nav";

const LINKS = [{ href: "/student", label: "My application" }];

export default async function StudentLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <>
      <PortalNav role="student" name={session?.name || "Student"} links={LINKS} />
      <main className="flex-1 mx-auto max-w-3xl w-full px-6 py-10">{children}</main>
    </>
  );
}
