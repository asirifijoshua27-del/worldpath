import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `PhD Applications | ${content.orgName}`,
    description: "Application support for PhD programs abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function PhdPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="PhD"
      title="PhD applications"
      body={content.phdInfo}
      fallback="We support Ghanaian students pursuing doctoral study abroad â€” from identifying the right advisors and programs to preparing research proposals and securing funding."
    />
  );
}

