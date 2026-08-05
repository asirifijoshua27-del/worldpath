import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Scholarships | ${content.orgName}`,
    description: "Scholarship and financial aid support for Ghanaian students applying to study abroad.",
  };
}

export default function ScholarshipsPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Funding"
      title="Scholarships & financial aid"
      body={content.scholarshipsInfo}
 fallback="We help you find and apply for merit-based and need-based scholarships and financial aid - especially at US universities, where most funding decisions are made as part of the admissions process itself."
    />
  );
}

