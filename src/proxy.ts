import { NextRequest, NextResponse } from "next/server";
import { jwtVerify } from "jose";

const SESSION_COOKIE = "wpg_session";

function getSecret(): Uint8Array {
  return new TextEncoder().encode(process.env.JWT_SECRET || "");
}

async function readRole(request: NextRequest): Promise<string | null> {
  const token = request.cookies.get(SESSION_COOKIE)?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, getSecret());
    return (payload.role as string) ?? null;
  } catch {
    return null;
  }
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const role = await readRole(request);

  // /account is shared across all roles — just needs any authenticated session.
  if (pathname.startsWith("/account")) {
    if (!role) {
      const loginUrl = new URL("/login", request.url);
      loginUrl.searchParams.set("next", pathname);
      return NextResponse.redirect(loginUrl);
    }
    return NextResponse.next();
  }

  const requiredRole = pathname.startsWith("/admin")
    ? "admin"
    : pathname.startsWith("/staff")
    ? "staff"
    : pathname.startsWith("/student")
    ? "student"
    : null;

  if (!requiredRole) return NextResponse.next();

  if (!role) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("next", pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (role !== requiredRole) {
    // Signed in, but wrong portal for their role — send them to their own portal.
    return NextResponse.redirect(new URL(`/${role}`, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/staff/:path*", "/student/:path*", "/account/:path*"],
};

