"use client";

export function DeleteButton({
  id,
  action,
  confirmLabel,
}: {
  id: string;
  action: (id: string) => Promise<void>;
  confirmLabel: string;
}) {
  return (
    <form
      action={action.bind(null, id)}
      onSubmit={(e) => {
        if (!confirm(confirmLabel)) e.preventDefault();
      }}
    >
      <button type="submit" className="text-red-700 hover:underline">
        Delete
      </button>
    </form>
  );
}
