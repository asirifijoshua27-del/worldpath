import { getSession } from "@/lib/auth";
import { PortalNav } from "@/components/portal-nav";

const LINKS = [
  { href: "/admin", label: "Dashboard" },
  { href: "/admin/content", label: "Site content" },
  { href: "/admin/staff", label: "Staff" },
  { href: "/admin/board", label: "Board" },
  { href: "/admin/students", label: "Students" },
  { href: "/admin/blog", label: "Blog" },
  { href: "/admin/impact", label: "Impact stories" },
  { href: "/admin/leads", label: "Leads" },
  { href: "/admin/users", label: "Accounts" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <>
      <PortalNav role="admin" name={session?.name || "Admin"} links={LINKS} />
      <main className="flex-1 mx-auto max-w-6xl w-full px-6 py-10">{children}</main>
    </>
  );
}
