import { ImageResponse } from "next/og";
import fs from "node:fs/promises";
import path from "node:path";
import { getSiteContent } from "@/lib/repo";
import { uploadDir } from "@/lib/uploads";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const size = { width: 32, height: 32 };
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
          <img src={logo} width={32} height={32} style={{ borderRadius: "50%", objectFit: "cover" }} />
        ) : (
          <span style={{ color: "#faf8f4", fontSize: 20 }}>W</span>
        )}
      </div>
    ),
    { ...size }
  );
}

