import Link from "next/link";
import { getSession } from "@/lib/auth";
import { logoutAction } from "@/app/actions/auth";
import { ChangePasswordForm } from "./change-password-form";

export default async function AccountPage() {
  const session = await getSession();

  return (
    <>
      <header className="border-b border-line">
        <div className="mx-auto max-w-3xl px-6 h-16 flex items-center justify-between">
          <Link href="/" className="font-display text-lg">
            WorldPath
          </Link>
          <div className="flex items-center gap-4 text-sm">
            {session && (
              <Link href={`/${session.role}`} className="text-teal hover:underline">
                ← Back to dashboard
              </Link>
            )}
            <form action={logoutAction}>
              <button className="text-teal hover:underline">Log out</button>
            </form>
          </div>
        </div>
      </header>
      <main className="flex-1 mx-auto max-w-3xl w-full px-6 py-10">
        <h1 className="font-display text-3xl mb-2">Account settings</h1>
        <p className="text-ink/60 mb-8">
          Signed in as {session?.name} ({session?.role}).
        </p>
        <h2 className="text-lg font-medium mb-4">Change password</h2>
        <ChangePasswordForm />
      </main>
    </>
  );
}
