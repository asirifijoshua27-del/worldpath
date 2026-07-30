# WorldPath Group Platform

A web app for WorldPath Group — helping talented Ghanaian students apply to
universities and scholarships abroad (USA, Canada, UK, Germany, Asia) —
with a public site, student registration/application tracking, and three
role-based portals (admin, staff, student).

## What's here

- **Public site** — mission, services, staff directory, Board of Directors
- **Impact page** (`/impact`) — live stats pulled straight from the database
  (no made-up numbers) plus real student success stories, managed from
  the admin portal
- **Blog** (`/blog`) — Markdown posts for scholarship guides and student
  stories, written and published from the admin portal. Each post gets
  proper SEO metadata, Open Graph tags, and Article structured data, and
  is included in the sitemap automatically once published — this is the
  page built specifically to compound organic Google traffic over time
- **Get Involved** (`/get-involved`) — an Apply CTA, a Donate section
  (your bank/mobile money details, editable from the admin portal, plus a
  short "I'm planning to give" form), and a Volunteer interest form.
  Submissions land in `/admin/leads` for follow-up
- **SEO basics** — `sitemap.xml` and `robots.txt` are generated
  automatically (updating live as you publish posts), plus per-page
  titles/descriptions
- **Student registration** — generates a WorldPath code (`WPG-2026-0001`)
  on sign-up; email must be verified before the student can set a password
- **Admin portal** (`/admin`) — edit all site content, manage staff/board
  profiles, manage every student record, assign staff, create staff logins,
  write blog posts, add impact stories, and follow up on leads — entirely
  through the UI, no code changes needed
- **Staff portal** (`/staff`) — see only your assigned students, update
  their application status, check off documents, leave notes
- **Student portal** (`/student`) — see your own status, checklist, and
  notes from your counselor

## Tech stack

- Next.js 16 (App Router, Server Actions) + TypeScript
- Tailwind CSS v4
- Node's built-in `node:sqlite` module as the database driver (see note below)
- `jose` for sessions (JWT in an httpOnly cookie), `bcryptjs` for password hashing

### A note on the database

The original plan was Prisma + PostgreSQL. That's still the right choice for
production, and the full intended schema is documented at
`docs/schema.prisma.reference` for exactly that migration. This build
substitutes Node's built-in `node:sqlite` module as the actual database
driver, because the sandboxed environment this was built in couldn't reach
the servers Prisma and Postgres need to download their binaries from.

`node:sqlite` needed no installs or network access at all, so it's what
actually runs the app you're looking at right now. The data model
(`src/lib/db.ts` and `src/lib/repo.ts`) mirrors the Prisma schema field for
field, so moving to Prisma + Postgres later is a mechanical port, not a
redesign — see "Migrating to Postgres" below.

**Before you deploy for real, read this:** `node:sqlite` writes to a local
file (`data/worldpath.db`), and uploaded staff/board photos are saved to
`data/uploads/` (served through `/api/uploads/[filename]` rather than
`/public`, since Next.js snapshots `/public` at build time and wouldn't
see files added while the server is running). Both need a persistent disk.
That's fine on a normal server or VPS (Render, Railway, Fly.io, a
DigitalOcean droplet, etc.). It will **not** work on serverless hosts like
Vercel, where the filesystem is wiped between requests — you'd lose data
and uploaded photos. If you want to deploy to Vercel, do the Postgres
migration below and swap photo storage for something like S3 or
Cloudinary.

## Getting started

```bash
npm install
cp .env.example .env   # already has sane local defaults
npm run dev
```

Open http://localhost:3000.

A default admin account is created automatically the first time the app runs:

- **Email:** `admin@worldpathgroup.org`
- **Password:** `ChangeMe123!`

Log in at `/login`, then change this password by creating your own admin
flow or updating it directly in the database — **do this before putting the
site anywhere public.**

### Sending real verification emails (Resend)

By default, no email provider is configured — verification links just print
to your terminal (wherever `npm run dev`/`npm start` is running) instead of
being emailed, so registration is fully testable with zero setup.

To send real emails:

1. Sign up at [resend.com](https://resend.com) (free tier: 3,000
   emails/month, 100/day — plenty to start).
2. Create an API key and set it as `RESEND_API_KEY` in `.env`.
3. **Verify your own sending domain in Resend** (Settings → Domains) and set
   `RESEND_FROM_EMAIL` to an address on that domain, e.g.
   `"WorldPath Group <no-reply@worldpathgroup.org>"`. Until you do this, you
   can test with Resend's shared `onboarding@resend.dev` address, but it
   will only deliver to your own Resend account email — not to real
   students — so don't launch with it.
4. Restart the server. Verification emails will now actually send; if
   Resend ever fails (bad key, rate limit, etc.), the app automatically
   falls back to logging the link to the console so no student gets stuck.

### Before you publish blog posts for real

Set `APP_URL` in `.env` to your actual production domain (e.g.
`https://worldpathgroup.org`). It's used to build the sitemap, canonical
URLs, and Open Graph image links — if it's left as `localhost`, search
engines and social previews will get broken links.

## Project structure

```
src/
  app/
    (public)         home, about, impact, blog, get-involved,
                       register, login, verify
    admin/            admin portal (content, staff, board, students,
                       blog, impact, leads, accounts)
    staff/             staff portal
    student/           student portal
    actions/           server actions (auth.ts, admin.ts, staff.ts,
                       blog.ts, impact.ts, leads.ts)
    sitemap.ts         auto-generated sitemap (includes published posts)
    robots.ts          robots.txt (blocks portal/API routes)
  lib/
    db.ts              database connection + schema migration + seed data
    repo.ts            typed data-access functions for every entity
    auth.ts            session (JWT) helpers
    email.ts           verification email sending (console.log by default)
    validators.ts       zod schemas for every form
  components/          shared UI (header, footer, portal nav, forms)
  proxy.ts             route protection by role (admin/staff/student)
docs/
  schema.prisma.reference   the target Prisma schema for a Postgres migration
```

## Migrating to Postgres + Prisma

1. `npm install prisma @prisma/client`
2. Copy `docs/schema.prisma.reference` to `prisma/schema.prisma`, set
   `provider = "postgresql"`, and set `DATABASE_URL` to your Postgres
   connection string in `.env`.
3. `npx prisma migrate dev --name init`
4. Rewrite the functions in `src/lib/repo.ts` to call `prisma.<model>.*`
   instead of raw SQL — the function names and shapes are designed to map
   over directly (e.g. `listStudents()`, `createStudentForUser()`).
5. Remove `src/lib/db.ts`.

## Known simplifications in this build

- No password-reset flow yet (only initial verification + set-password).
- Student `documents` checklist starts from one fixed default list; making
  it customizable per application is a natural next step.
