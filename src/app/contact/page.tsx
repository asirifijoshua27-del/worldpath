import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { ContactForm } from "./contact-form";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Contact | ${content.orgName}`,
    description: `Get in touch with ${content.orgName}.`,
  };
}

export default function ContactPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-4xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Contact</p>
          <h1 className="font-display text-4xl mt-4 mb-10">Get in touch</h1>

          <div className="grid sm:grid-cols-2 gap-12">
            <div>
              <h2 className="font-display text-lg mb-3">Reach us directly</h2>
              <div className="space-y-1 text-ink/70">
                {content.contactEmail && <p>{content.contactEmail}</p>}
                {content.contactPhone && <p>{content.contactPhone}</p>}
                {content.address && <p className="whitespace-pre-line">{content.address}</p>}
              </div>
            </div>
            <div>
              <h2 className="font-display text-lg mb-3">Send a message</h2>
              <ContactForm />
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

