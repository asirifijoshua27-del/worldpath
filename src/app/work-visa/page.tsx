import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Work Visa Support | ${content.orgName}`,
    description: "Application support for Ghanaians pursuing a work visa abroad, in any profession or destination.",
  };
}

export default function WorkVisaPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Work visa support"
      title="Work visa applications"
      body={content.workVisaInfo}
      fallback="Not every path abroad runs through a classroom. We support Ghanaians pursuing a work visa in any profession and any destination - reviewing your documents, helping you understand what a given route actually requires, and keeping your application on track from your own portal."
      applyHref="/register/work-visa"
    />
  );
}
