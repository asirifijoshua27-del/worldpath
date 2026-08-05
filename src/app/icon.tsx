import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
// Google requires at least 48x48 to reliably show a favicon in search
// results at all (smaller sizes often just fall back to a generic globe
// icon) â€” 128x128 gives good headroom and stays sharp on high-DPI screens.
export const size = { width: 128, height: 128 };
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

export default async function Icon() {
  const content = getSiteContent();
  const logo = await logoDataUri(content.logoUrl);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: logo ? "transparent" : "#0a2e3d",
          borderRadius: "50%",
        }}
      >
        {logo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} width={128} height={128} style={{ borderRadius: "50%", objectFit: "cover" }} />
        ) : (
          <span style={{ color: "#faf8f4", fontSize: 72 }}>W</span>
        )}
      </div>
    ),
    { ...size }
  );
}

