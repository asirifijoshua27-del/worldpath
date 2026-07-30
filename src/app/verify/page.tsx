import { getVerificationToken } from "@/lib/repo";
import { VerifyForm } from "./verify-form";

export default async function VerifyPage({
  searchParams,
}: {
  searchParams: Promise<{ token?: string }>;
}) {
  const { token } = await searchParams;

  if (!token) {
    return <Message title="Missing verification token" body="Please use the link from your email." />;
  }

  const record = getVerificationToken(token);
  if (!record) {
    return <Message title="Invalid link" body="This verification link doesn't exist. Please register again." />;
  }
  if (record.used) {
    return (
      <Message
        title="Already verified"
        body="This link has already been used. If you haven't set a password yet, please contact us."
      />
    );
  }
  if (new Date(record.expiresAt) < new Date()) {
    return <Message title="Link expired" body="This verification link has expired. Please register again." />;
  }

  return (
    <main className="flex-1 flex items-center justify-center px-6 py-16">
      <div className="w-full max-w-md">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Almost there</p>
        <h1 className="font-display text-3xl mt-3 mb-2">Set your password</h1>
        <p className="text-sm text-ink/70 mb-8">Your email is verified. Choose a password to finish setting up your account.</p>
        <VerifyForm token={token} />
      </div>
    </main>
  );
}

function Message({ title, body }: { title: string; body: string }) {
  return (
    <main className="flex-1 flex items-center justify-center px-6 py-16">
      <div className="max-w-md text-center">
        <h1 className="font-display text-2xl mb-3">{title}</h1>
        <p className="text-ink/70">{body}</p>
      </div>
    </main>
  );
}
