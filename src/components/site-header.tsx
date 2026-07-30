import Link from "next/link";

export function SiteHeader({ orgName }: { orgName: string }) {
  return (
    <header className="border-b border-line bg-paper/95 backdrop-blur sticky top-0 z-40">
      <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 group">
          <span className="w-8 h-8 rounded-full bg-ink text-paper grid place-items-center font-display text-sm">
            W
          </span>
          <span className="font-display text-lg tracking-tight">{orgName}</span>
        </Link>
        <nav className="flex items-center gap-5 sm:gap-6 text-sm">
          <Link href="/about" className="hover:text-gold-deep transition-colors hidden md:inline">
            About &amp; Team
          </Link>
          <Link href="/impact" className="hover:text-gold-deep transition-colors hidden sm:inline">
            Impact
          </Link>
          <Link href="/blog" className="hover:text-gold-deep transition-colors hidden sm:inline">
            Blog
          </Link>
          <Link href="/get-involved" className="hover:text-gold-deep transition-colors hidden md:inline">
            Get Involved
          </Link>
          <Link href="/login" className="hover:text-gold-deep transition-colors">
            Log in
          </Link>
          <Link
            href="/register"
            className="rounded-full bg-ink text-paper px-4 py-2 hover:bg-teal transition-colors"
          >
            Apply now
          </Link>
        </nav>
      </div>
    </header>
  );
}
