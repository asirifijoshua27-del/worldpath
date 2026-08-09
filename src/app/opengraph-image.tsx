import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const alt = "WorldPath Group";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

async function logoDataUri(logoUrl: string | null): Promise<string | null> {
  if (!logoUrl || !logoUrl.startsWith("/api/uploads/")) return null;
  try {
    const filename = logoUrl.replace("/api/uploads/", "");
    const filePath = path.join(uploadDir(), filename);
    const buffer = await fs.readFile(filePath);
    const ext = path.extname(filename).slice(1);
    const mime = ext === "jpg" ? "jpeg" : ext;
    return `data:image/${mime};base64,${buffer.toString("base64")}`;
  } catch {
    return null;
  }
}

export default async function Image() {
  const content = getSiteContent();
  const logo = await logoDataUri(content.logoUrl);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: "#082029",
          color: "#faf8f4",
        }}
      >
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={logo}
            width={180}
            height={180}
            style={{ borderRadius: "50%", marginBottom: 36, objectFit: "cover" }}
          />
        ) : (
          <div
            style={{
              width: 150,
              height: 150,
              borderRadius: "50%",
              background: "#0f6e8c",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 68,
              marginBottom: 36,
            }}
          >
            W
          </div>
        )}
        <div style={{ fontSize: 58, fontWeight: 600 }}>{content.orgName}</div>
        <div style={{ fontSize: 28, color: "#faf8f4b3", marginTop: 18, maxWidth: 820, textAlign: "center" }}>
          {content.tagline}
        </div>
      </div>
    ),
    { ...size }
  );
}

