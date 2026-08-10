import { CheckIcon } from "@/components/check-icon";

export default async function CheckEmailPage({
  searchParams,
}: {
  searchParams: Promise<{ email?: string }>;
}) {
  const { email } = await searchParams;

  return (
    <main className="flex-1 flex items-center justify-center px-6 py-16">
      <div className="max-w-md text-center">
        <span className="inline-grid place-items-center w-14 h-14 rounded-full bg-teal/10 text-teal mb-6">
          <CheckIcon className="w-6 h-6" />
        </span>
        <h1 className="font-display text-2xl mb-3">Check your email</h1>
        <p className="text-ink/70 leading-relaxed">
          We've sent a verification link to <strong>{email || "your email address"}</strong>. Open it to
          verify your account and set your password.
        </p>
        <p className="text-xs text-ink/40 mt-6">
          Running locally without email configured? The link is printed to the server console.
        </p>
      </div>
    </main>
  );
}
