import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Undergraduate Applications | ${content.orgName}`,
    description: "Application support for undergraduate study abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function UndergraduatePage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Undergraduate"
      title="Undergraduate applications"
      body={content.undergradInfo}
 fallback="We help Ghanaian students build a competitive undergraduate application - from choosing the right universities to writing standout essays and finding scholarships to make it affordable."
    />
  );
}

