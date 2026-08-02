import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Master's Applications | ${content.orgName}`,
    description: "Application support for master's degrees abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function MastersPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Master's"
      title="Master's applications"
      body={content.mastersInfo}
      fallback="We support Ghanaian graduates applying for master's programs abroad â€” from selecting programs aligned with your career goals to strengthening your statement of purpose and finding funding."
    />
  );
}

