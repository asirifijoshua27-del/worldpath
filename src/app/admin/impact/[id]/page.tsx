import { notFound } from "next/navigation";
import { getImpactStoryById } from "@/lib/repo";
import { ImpactStoryForm } from "../impact-form";

export const dynamic = "force-dynamic";

export default async function EditImpactStoryPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const story = getImpactStoryById(id);
  if (!story) notFound();

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit impact story</h1>
      <ImpactStoryForm story={story} />
    </div>
  );
}
