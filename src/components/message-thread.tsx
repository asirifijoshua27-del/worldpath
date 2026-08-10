import type { Role } from "@/types";

export interface ThreadMessage {
  id: string;
  text: string;
  attachmentUrl: string | null;
  authorName: string;
  authorRole: Role;
  createdAt: string;
}

export function MessageThread({ messages, viewerRole }: { messages: ThreadMessage[]; viewerRole: Role }) {
  if (messages.length === 0) {
    return <p className="text-sm text-ink/50 italic">No messages yet.</p>;
  }

  return (
    <div className="space-y-4">
      {messages.map((m) => {
        const isMine = m.authorRole === viewerRole;
        return (
          <div key={m.id} className={`flex ${isMine ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-md rounded-xl px-4 py-3 ${
                isMine ? "bg-ink text-paper" : "bg-paper-dim border border-line"
              }`}
            >
              <p className={`text-xs mb-1 ${isMine ? "text-paper/60" : "text-ink/50"}`}>
                {isMine ? "You" : m.authorName} &middot; {new Date(m.createdAt).toLocaleString()}
              </p>
              {m.text && <p className="text-sm whitespace-pre-line">{m.text}</p>}
              {m.attachmentUrl && (
                <a href={m.attachmentUrl} target="_blank" rel="noopener noreferrer" className="block mt-2">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={m.attachmentUrl}
                    alt="Attachment"
                    className="rounded-lg max-h-64 border border-black/10"
                  />
                </a>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

