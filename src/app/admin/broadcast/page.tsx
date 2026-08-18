import { BroadcastForm } from "./broadcast-form";

export default function AdminBroadcastPage() {
  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Message a group</h1>
      <p className="text-ink/60 mb-8">
        Sends the same email (and an in-app notification) to everyone in the group you pick. Each person only
        sees their own copy.
      </p>
      <BroadcastForm />
    </div>
  );
}
