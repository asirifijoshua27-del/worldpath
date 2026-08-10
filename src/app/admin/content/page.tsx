import { getSiteContent } from "@/lib/repo";
import { ContentForm } from "./content-form";

export const dynamic = "force-dynamic";

export default function AdminContentPage() {
  const content = getSiteContent();
  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Site content</h1>
      <p className="text-ink/60 mb-8">
        Edit what visitors see on the homepage and about page - no code required.
      </p>
      <ContentForm content={content} />
    </div>
  );
}
