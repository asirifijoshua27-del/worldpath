# WorldPath Group - document uploads, two-way messaging, photo lightbox,
# OG image/favicon fix, board/staff visual distinction, free SHS application form
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'

# Remove files that no longer exist in this version
Remove-Item -LiteralPath 'src/app/staff/students/[id]/note-form.tsx' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath 'src/app/favicon.ico' -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
import { DatabaseSync } from "node:sqlite";
import path from "node:path";
import fs from "node:fs";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";

// This project uses Node's built-in `node:sqlite` module as its database
// driver so the app runs with zero native-binary installs. The data model
// mirrors docs/schema.prisma.reference exactly, so migrating to Prisma +
// Postgres later is a mechanical port, not a redesign. See README.md.

const DB_PATH = process.env.DATABASE_FILE || path.join(process.cwd(), "data", "worldpath.db");

function getDb(): DatabaseSync {
  const g = globalThis as unknown as { __worldpathDb?: DatabaseSync };
  if (g.__worldpathDb) return g.__worldpathDb;

  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const db = new DatabaseSync(DB_PATH);
  db.exec("PRAGMA journal_mode = WAL;");
  db.exec("PRAGMA foreign_keys = ON;");
  migrate(db);
  seed(db);
  g.__worldpathDb = db;
  return db;
}

function migrate(db: DatabaseSync) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      passwordHash TEXT,
      role TEXT NOT NULL DEFAULT 'student',
      name TEXT NOT NULL,
      emailVerified INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS staff_profiles (
      id TEXT PRIMARY KEY,
      userId TEXT UNIQUE REFERENCES users(id),
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS board_members (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      bio TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      sortOrder INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS students (
      id TEXT PRIMARY KEY,
      code TEXT UNIQUE NOT NULL,
      userId TEXT UNIQUE NOT NULL REFERENCES users(id),
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      targetCountries TEXT NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'new',
      assignedStaffId TEXT REFERENCES staff_profiles(id),
      documents TEXT NOT NULL DEFAULT '[]',
      scholarshipInterest INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS student_notes (
      id TEXT PRIMARY KEY,
      studentId TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      authorId TEXT NOT NULL REFERENCES users(id),
      text TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS site_content (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      orgName TEXT NOT NULL DEFAULT 'WorldPath Group',
      tagline TEXT NOT NULL DEFAULT '',
      mission TEXT NOT NULL DEFAULT '',
      vision TEXT NOT NULL DEFAULT '',
      contactEmail TEXT NOT NULL DEFAULT '',
      contactPhone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS email_verifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT UNIQUE NOT NULL,
      expiresAt TEXT NOT NULL,
      used INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS counters (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS blog_posts (
      id TEXT PRIMARY KEY,
      slug TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      excerpt TEXT NOT NULL DEFAULT '',
      body TEXT NOT NULL DEFAULT '',
      coverImageUrl TEXT,
      tags TEXT NOT NULL DEFAULT '[]',
      authorName TEXT NOT NULL DEFAULT '',
      published INTEGER NOT NULL DEFAULT 0,
      publishedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS impact_stories (
      id TEXT PRIMARY KEY,
      studentName TEXT NOT NULL,
      headline TEXT NOT NULL,
      story TEXT NOT NULL DEFAULT '',
      photoUrl TEXT,
      destinationCountry TEXT NOT NULL DEFAULT '',
      targetLevel TEXT NOT NULL DEFAULT 'undergrad',
      featured INTEGER NOT NULL DEFAULT 0,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS volunteer_leads (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL DEFAULT 'volunteer',
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      message TEXT NOT NULL DEFAULT '',
      handled INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  `);

  // Columns added after the initial release go here as best-effort ALTERs
  // (existing databases won't have them; CREATE TABLE IF NOT EXISTS above
  // only helps brand-new installs). Safe to ignore "duplicate column".
  const alters = [
    "ALTER TABLE site_content ADD COLUMN donateInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN logoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN caretakingInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE student_notes ADD COLUMN attachmentUrl TEXT",
    "ALTER TABLE students ADD COLUMN currentEducationLevel TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN schoolName TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE students ADD COLUMN applicationType TEXT NOT NULL DEFAULT 'standard'",
  ];
  for (const sql of alters) {
    try {
      db.exec(sql);
    } catch {
      // Column already exists — fine.
    }
  }
}

function seed(db: DatabaseSync) {
  const now = new Date().toISOString();

  const contentRow = db.prepare("SELECT id FROM site_content WHERE id = 1").get();
  if (!contentRow) {
    db.prepare(
      `INSERT INTO site_content (id, orgName, tagline, mission, vision, contactEmail, contactPhone, address, donateInfo, caretakingInfo)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      "WorldPath Group",
      "Opening the world's classrooms to Ghana's brightest students.",
      "WorldPath Group helps talented undergraduate, master's, and PhD students across Ghana apply to universities abroad and secure the scholarships that make it possible \u2014 with priority access for students whose families cannot otherwise afford it, including orphans.",
      "A future where a student's potential, not their family's income, determines which universities are open to them.",
      "hello@worldpathgroup.org",
      "",
      "Accra, Ghana",
      "Update this from Admin \u2192 Site content with your bank account or mobile money details.",
      "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities \u2014 because a student's wellbeing at home is part of their path to university too."
    );
  }

  const adminRow = db.prepare("SELECT id FROM users WHERE role = 'admin' LIMIT 1").get();
  if (!adminRow) {
    const id = randomUUID();
    const passwordHash = bcrypt.hashSync("ChangeMe123!", 10);
    db.prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, 'admin', ?, 1, ?, ?)`
    ).run(id, "admin", "admin@worldpathgroup.org", passwordHash, "WorldPath Admin", now, now);
  }
}

// node:sqlite returns row objects with a null prototype. That's invisible
// almost everywhere, but React Server Components refuse to serialize
// null-prototype objects when passing data to Client Components ("Only
// plain objects... can be passed"). This thin wrapper spreads every row
// into a genuine plain object so callers never have to think about it.
type SQLInputValue = null | number | bigint | string | NodeJS.ArrayBufferView;

interface PlainStatement {
  get(...params: SQLInputValue[]): Record<string, unknown> | undefined;
  all(...params: SQLInputValue[]): Record<string, unknown>[];
  run(...params: SQLInputValue[]): unknown;
}

interface PlainDb {
  prepare(sql: string): PlainStatement;
}

function wrapDb(raw: DatabaseSync): PlainDb {
  return {
    prepare(sql: string) {
      const stmt = raw.prepare(sql);
      return {
        get: (...params: SQLInputValue[]) => {
          const row = stmt.get(...params);
          return row ? { ...(row as object) } : undefined;
        },
        all: (...params: SQLInputValue[]) => {
          return stmt.all(...params).map((row) => ({ ...(row as object) }));
        },
        run: (...params: SQLInputValue[]) => stmt.run(...params),
      };
    },
  };
}

export function db(): PlainDb {
  return wrapDb(getDb());
}

export function nowIso(): string {
  return new Date().toISOString();
}

export function newId(): string {
  return randomUUID();
}

/** Generates the next sequential student code for the current year, e.g. WPG-2026-0001 */
export function nextStudentCode(): string {
  const year = new Date().getFullYear();
  const counterId = `student-${year}`;
  const database = getDb();
  const existing = database.prepare("SELECT value FROM counters WHERE id = ?").get(counterId) as
    | { value: number }
    | undefined;
  const next = (existing?.value ?? 0) + 1;
  if (existing) {
    database.prepare("UPDATE counters SET value = ? WHERE id = ?").run(next, counterId);
  } else {
    database.prepare("INSERT INTO counters (id, value) VALUES (?, ?)").run(counterId, next);
  }
  return `WPG-${year}-${String(next).padStart(4, "0")}`;
}

'@ | Set-Content -LiteralPath "src/lib/db.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/types" | Out-Null
@'
export type Role = "admin" | "staff" | "student";

export type TargetLevel = "undergrad" | "masters" | "phd";

export type ApplicationStatus =
  | "new"
  | "documents_pending"
  | "in_review"
  | "submitted"
  | "scholarship_review"
  | "accepted"
  | "not_proceeding";

export const APPLICATION_STATUSES: { value: ApplicationStatus; label: string }[] = [
  { value: "new", label: "New" },
  { value: "documents_pending", label: "Documents pending" },
  { value: "in_review", label: "In review" },
  { value: "submitted", label: "Submitted" },
  { value: "scholarship_review", label: "Scholarship review" },
  { value: "accepted", label: "Accepted" },
  { value: "not_proceeding", label: "Not proceeding" },
];

export const TARGET_LEVELS: { value: TargetLevel; label: string }[] = [
  { value: "undergrad", label: "Undergraduate" },
  { value: "masters", label: "Master's" },
  { value: "phd", label: "PhD" },
];

export const TARGET_COUNTRIES = ["USA", "Canada", "UK", "Germany", "Other Europe", "Asia"];

export type CurrentEducationLevel = "shs_current" | "shs_graduate" | "tertiary" | "graduate" | "other";

export const CURRENT_EDUCATION_LEVELS: { value: CurrentEducationLevel; label: string }[] = [
  { value: "shs_graduate", label: "Completed Senior High School / awaiting results" },
  { value: "tertiary", label: "Currently in university / tertiary institution" },
  { value: "graduate", label: "Already completed a university degree" },
  { value: "other", label: "Other" },
];

export type ApplicationType = "standard" | "free_shs";

export interface DocumentItem {
  name: string;
  done: boolean;
  fileUrl?: string | null;
  uploadedAt?: string | null;
}

export interface UserRecord {
  id: string;
  username: string;
  email: string;
  passwordHash: string | null;
  role: Role;
  name: string;
  emailVerified: number;
  createdAt: string;
  updatedAt: string;
}

export interface StaffProfileRecord {
  id: string;
  userId: string | null;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export interface BoardMemberRecord {
  id: string;
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  sortOrder: number;
}

export interface StudentRecord {
  id: string;
  code: string;
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string; // JSON-encoded string[]
  status: ApplicationStatus;
  assignedStaffId: string | null;
  documents: string; // JSON-encoded DocumentItem[]
  scholarshipInterest: number;
  currentEducationLevel: CurrentEducationLevel | "";
  schoolName: string;
  applicationType: ApplicationType;
  createdAt: string;
  updatedAt: string;
}

export interface StudentNoteRecord {
  id: string;
  studentId: string;
  authorId: string;
  text: string;
  attachmentUrl: string | null;
  createdAt: string;
}

export interface SiteContentRecord {
  id: number;
  orgName: string;
  tagline: string;
  mission: string;
  vision: string;
  contactEmail: string;
  contactPhone: string;
  address: string;
  donateInfo: string;
  logoUrl: string | null;
  caretakingInfo: string;
}

export interface BlogPostRecord {
  id: string;
  slug: string;
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl: string | null;
  tags: string; // JSON-encoded string[]
  authorName: string;
  published: number;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ImpactStoryRecord {
  id: string;
  studentName: string;
  headline: string;
  story: string;
  photoUrl: string | null;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: number;
  sortOrder: number;
  createdAt: string;
}

export type LeadType = "volunteer" | "donate" | "apply_interest";

export interface VolunteerLeadRecord {
  id: string;
  type: LeadType;
  name: string;
  email: string;
  phone: string | null;
  message: string;
  handled: number;
  createdAt: string;
}

export interface SessionPayload {
  userId: string;
  role: Role;
  name: string;
}

'@ | Set-Content -LiteralPath "src/types/index.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
import { db, newId, nowIso, nextStudentCode } from "@/lib/db";
import type {
  UserRecord,
  StaffProfileRecord,
  BoardMemberRecord,
  StudentRecord,
  StudentNoteRecord,
  SiteContentRecord,
  BlogPostRecord,
  ImpactStoryRecord,
  VolunteerLeadRecord,
  LeadType,
  Role,
  TargetLevel,
  DocumentItem,
} from "@/types";

const DEFAULT_CHECKLIST: DocumentItem[] = [
  { name: "Passport / national ID", done: false },
  { name: "Academic transcripts", done: false },
  { name: "Personal statement / essay", done: false },
  { name: "Recommendation letters", done: false },
  { name: "English proficiency test (if required)", done: false },
  { name: "Financial / sponsorship documents", done: false },
];

// ---------- Users ----------

export function getUserByEmail(email: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE email = ?").get(email) as UserRecord | undefined;
}

export function getUserByUsername(username: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE username = ?").get(username) as UserRecord | undefined;
}

export function getUserById(id: string): UserRecord | undefined {
  return db().prepare("SELECT * FROM users WHERE id = ?").get(id) as UserRecord | undefined;
}

export function listUsers(): UserRecord[] {
  return db().prepare("SELECT * FROM users ORDER BY createdAt DESC").all() as unknown as UserRecord[];
}

export function createUser(input: {
  username: string;
  email: string;
  name: string;
  role: Role;
  passwordHash?: string | null;
  emailVerified?: boolean;
}): UserRecord {
  const id = newId();
  const now = nowIso();
  db()
    .prepare(
      `INSERT INTO users (id, username, email, passwordHash, role, name, emailVerified, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.username,
      input.email,
      input.passwordHash ?? null,
      input.role,
      input.name,
      input.emailVerified ? 1 : 0,
      now,
      now
    );
  return getUserById(id)!;
}

export function setUserPassword(userId: string, passwordHash: string) {
  db()
    .prepare("UPDATE users SET passwordHash = ?, updatedAt = ? WHERE id = ?")
    .run(passwordHash, nowIso(), userId);
}

export function markEmailVerified(userId: string) {
  db().prepare("UPDATE users SET emailVerified = 1, updatedAt = ? WHERE id = ?").run(nowIso(), userId);
}

// ---------- Email verification tokens ----------

export function createVerificationToken(userId: string, token: string, ttlHours = 48) {
  const expiresAt = new Date(Date.now() + ttlHours * 3600 * 1000).toISOString();
  db()
    .prepare(
      `INSERT INTO email_verifications (id, userId, token, expiresAt, used, createdAt)
       VALUES (?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), userId, token, expiresAt, nowIso());
}

export function getVerificationToken(token: string) {
  return db().prepare("SELECT * FROM email_verifications WHERE token = ?").get(token) as
    | { id: string; userId: string; token: string; expiresAt: string; used: number }
    | undefined;
}

export function consumeVerificationToken(token: string) {
  db().prepare("UPDATE email_verifications SET used = 1 WHERE token = ?").run(token);
}

// ---------- Staff profiles ----------

export function listStaff(): StaffProfileRecord[] {
  return db().prepare("SELECT * FROM staff_profiles ORDER BY sortOrder ASC, name ASC").all() as unknown as StaffProfileRecord[];
}

export function getStaffById(id: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE id = ?").get(id) as StaffProfileRecord | undefined;
}

export function getStaffByUserId(userId: string): StaffProfileRecord | undefined {
  return db().prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
    | StaffProfileRecord
    | undefined;
}

export function createStaff(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  userId?: string | null;
  sortOrder?: number;
}): StaffProfileRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO staff_profiles (id, userId, name, title, bio, photoUrl, sortOrder)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(id, input.userId ?? null, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getStaffById(id)!;
}

export function updateStaff(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(
      `UPDATE staff_profiles SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`
    )
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteStaff(id: string) {
  db().prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(id);
  db().prepare("DELETE FROM staff_profiles WHERE id = ?").run(id);
}

// ---------- Board members ----------

export function listBoardMembers(): BoardMemberRecord[] {
  return db().prepare("SELECT * FROM board_members ORDER BY sortOrder ASC, name ASC").all() as unknown as BoardMemberRecord[];
}

export function getBoardMemberById(id: string): BoardMemberRecord | undefined {
  return db().prepare("SELECT * FROM board_members WHERE id = ?").get(id) as BoardMemberRecord | undefined;
}

export function createBoardMember(input: {
  name: string;
  title: string;
  bio: string;
  photoUrl?: string;
  sortOrder?: number;
}): BoardMemberRecord {
  const id = newId();
  db()
    .prepare(`INSERT INTO board_members (id, name, title, bio, photoUrl, sortOrder) VALUES (?, ?, ?, ?, ?, ?)`)
    .run(id, input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0);
  return getBoardMemberById(id)!;
}

export function updateBoardMember(
  id: string,
  input: { name: string; title: string; bio: string; photoUrl?: string; sortOrder?: number }
) {
  db()
    .prepare(`UPDATE board_members SET name = ?, title = ?, bio = ?, photoUrl = ?, sortOrder = ? WHERE id = ?`)
    .run(input.name, input.title, input.bio, input.photoUrl ?? null, input.sortOrder ?? 0, id);
}

export function deleteBoardMember(id: string) {
  db().prepare("DELETE FROM board_members WHERE id = ?").run(id);
}

// ---------- Students ----------

export function listStudents(): StudentRecord[] {
  return db().prepare("SELECT * FROM students ORDER BY createdAt DESC").all() as unknown as StudentRecord[];
}

export function listStudentsByStaff(staffId: string): StudentRecord[] {
  return db()
    .prepare("SELECT * FROM students WHERE assignedStaffId = ? ORDER BY createdAt DESC")
    .all(staffId) as unknown as StudentRecord[];
}

export function getStudentById(id: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE id = ?").get(id) as StudentRecord | undefined;
}

export function getStudentByUserId(userId: string): StudentRecord | undefined {
  return db().prepare("SELECT * FROM students WHERE userId = ?").get(userId) as StudentRecord | undefined;
}

export function createStudentForUser(input: {
  userId: string;
  targetLevel: TargetLevel;
  targetCountries: string[];
  scholarshipInterest: boolean;
  currentEducationLevel?: string;
  schoolName?: string;
  applicationType?: "standard" | "free_shs";
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      code,
      input.userId,
      input.targetLevel,
      JSON.stringify(input.targetCountries),
      JSON.stringify(DEFAULT_CHECKLIST),
      input.scholarshipInterest ? 1 : 0,
      input.currentEducationLevel ?? "",
      input.schoolName ?? "",
      input.applicationType ?? "standard",
      now,
      now
    );
  return getStudentById(id)!;
}

export function updateStudentStatus(id: string, status: string) {
  db().prepare("UPDATE students SET status = ?, updatedAt = ? WHERE id = ?").run(status, nowIso(), id);
}

export function assignStudentStaff(id: string, staffId: string | null) {
  db().prepare("UPDATE students SET assignedStaffId = ?, updatedAt = ? WHERE id = ?").run(staffId, nowIso(), id);
}

export function updateStudentDocuments(id: string, documents: DocumentItem[]) {
  db()
    .prepare("UPDATE students SET documents = ?, updatedAt = ? WHERE id = ?")
    .run(JSON.stringify(documents), nowIso(), id);
}

export function updateStudentTargets(
  id: string,
  input: { targetLevel: TargetLevel; targetCountries: string[]; scholarshipInterest: boolean }
) {
  db()
    .prepare(
      "UPDATE students SET targetLevel = ?, targetCountries = ?, scholarshipInterest = ?, updatedAt = ? WHERE id = ?"
    )
    .run(input.targetLevel, JSON.stringify(input.targetCountries), input.scholarshipInterest ? 1 : 0, nowIso(), id);
}

// ---------- Student notes ----------

export function listNotesForStudent(
  studentId: string
): (StudentNoteRecord & { authorName: string; authorRole: Role })[] {
  return db()
    .prepare(
      `SELECT n.*, u.name as authorName, u.role as authorRole FROM student_notes n
       JOIN users u ON u.id = n.authorId
       WHERE n.studentId = ? ORDER BY n.createdAt ASC`
    )
    .all(studentId) as unknown as (StudentNoteRecord & { authorName: string; authorRole: Role })[];
}

export function addNote(studentId: string, authorId: string, text: string, attachmentUrl?: string | null) {
  db()
    .prepare(
      `INSERT INTO student_notes (id, studentId, authorId, text, attachmentUrl, createdAt) VALUES (?, ?, ?, ?, ?, ?)`
    )
    .run(newId(), studentId, authorId, text, attachmentUrl ?? null, nowIso());
}

// ---------- Site content ----------

export function getSiteContent(): SiteContentRecord {
  return db().prepare("SELECT * FROM site_content WHERE id = 1").get() as unknown as SiteContentRecord;
}

export function updateSiteContent(input: Omit<SiteContentRecord, "id">) {
  db()
    .prepare(
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, caretakingInfo = ?
       WHERE id = 1`
    )
    .run(
      input.orgName,
      input.tagline,
      input.mission,
      input.vision,
      input.contactEmail,
      input.contactPhone,
      input.address,
      input.donateInfo,
      input.logoUrl,
      input.caretakingInfo
    );
}

// ---------- Blog posts ----------

function slugify(title: string): string {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .slice(0, 80);
}

export function uniqueSlug(title: string, excludeId?: string): string {
  const base = slugify(title) || "post";
  let slug = base;
  let n = 1;
  while (true) {
    const existing = db().prepare("SELECT id FROM blog_posts WHERE slug = ?").get(slug) as
      | { id: string }
      | undefined;
    if (!existing || existing.id === excludeId) return slug;
    n += 1;
    slug = `${base}-${n}`;
  }
}

export function listPublishedPosts(): BlogPostRecord[] {
  return db()
    .prepare("SELECT * FROM blog_posts WHERE published = 1 ORDER BY publishedAt DESC")
    .all() as unknown as BlogPostRecord[];
}

export function listAllPosts(): BlogPostRecord[] {
  return db().prepare("SELECT * FROM blog_posts ORDER BY createdAt DESC").all() as unknown as BlogPostRecord[];
}

export function getPostBySlug(slug: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE slug = ?").get(slug) as unknown as
    | BlogPostRecord
    | undefined;
}

export function getPostById(id: string): BlogPostRecord | undefined {
  return db().prepare("SELECT * FROM blog_posts WHERE id = ?").get(id) as unknown as BlogPostRecord | undefined;
}

export function createPost(input: {
  title: string;
  excerpt: string;
  body: string;
  coverImageUrl?: string;
  tags: string[];
  authorName: string;
  published: boolean;
}): BlogPostRecord {
  const id = newId();
  const now = nowIso();
  const slug = uniqueSlug(input.title);
  db()
    .prepare(
      `INSERT INTO blog_posts
        (id, slug, title, excerpt, body, coverImageUrl, tags, authorName, published, publishedAt, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      input.published ? now : null,
      now,
      now
    );
  return getPostById(id)!;
}

export function updatePost(
  id: string,
  input: {
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl?: string;
    tags: string[];
    authorName: string;
    published: boolean;
  }
) {
  const existing = getPostById(id);
  if (!existing) return;
  const slug = existing.title === input.title ? existing.slug : uniqueSlug(input.title, id);
  const publishedAt = input.published ? existing.publishedAt || nowIso() : null;
  db()
    .prepare(
      `UPDATE blog_posts SET slug = ?, title = ?, excerpt = ?, body = ?, coverImageUrl = ?, tags = ?, authorName = ?, published = ?, publishedAt = ?, updatedAt = ?
       WHERE id = ?`
    )
    .run(
      slug,
      input.title,
      input.excerpt,
      input.body,
      input.coverImageUrl ?? null,
      JSON.stringify(input.tags),
      input.authorName,
      input.published ? 1 : 0,
      publishedAt,
      nowIso(),
      id
    );
}

export function deletePost(id: string) {
  db().prepare("DELETE FROM blog_posts WHERE id = ?").run(id);
}

// ---------- Impact stories ----------

export function listImpactStories(): ImpactStoryRecord[] {
  return db()
    .prepare("SELECT * FROM impact_stories ORDER BY sortOrder ASC, createdAt DESC")
    .all() as unknown as ImpactStoryRecord[];
}

export function getImpactStoryById(id: string): ImpactStoryRecord | undefined {
  return db().prepare("SELECT * FROM impact_stories WHERE id = ?").get(id) as unknown as
    | ImpactStoryRecord
    | undefined;
}

export function createImpactStory(input: {
  studentName: string;
  headline: string;
  story: string;
  photoUrl?: string;
  destinationCountry: string;
  targetLevel: TargetLevel;
  featured: boolean;
  sortOrder?: number;
}): ImpactStoryRecord {
  const id = newId();
  db()
    .prepare(
      `INSERT INTO impact_stories
        (id, studentName, headline, story, photoUrl, destinationCountry, targetLevel, featured, sortOrder, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      id,
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      nowIso()
    );
  return getImpactStoryById(id)!;
}

export function updateImpactStory(
  id: string,
  input: {
    studentName: string;
    headline: string;
    story: string;
    photoUrl?: string;
    destinationCountry: string;
    targetLevel: TargetLevel;
    featured: boolean;
    sortOrder?: number;
  }
) {
  db()
    .prepare(
      `UPDATE impact_stories SET studentName = ?, headline = ?, story = ?, photoUrl = ?, destinationCountry = ?, targetLevel = ?, featured = ?, sortOrder = ?
       WHERE id = ?`
    )
    .run(
      input.studentName,
      input.headline,
      input.story,
      input.photoUrl ?? null,
      input.destinationCountry,
      input.targetLevel,
      input.featured ? 1 : 0,
      input.sortOrder ?? 0,
      id
    );
}

export function deleteImpactStory(id: string) {
  db().prepare("DELETE FROM impact_stories WHERE id = ?").run(id);
}

// ---------- Volunteer / donate / apply leads ----------

export function listLeads(): VolunteerLeadRecord[] {
  return db().prepare("SELECT * FROM volunteer_leads ORDER BY createdAt DESC").all() as unknown as VolunteerLeadRecord[];
}

export function createLead(input: { type: LeadType; name: string; email: string; phone?: string; message: string }) {
  db()
    .prepare(
      `INSERT INTO volunteer_leads (id, type, name, email, phone, message, handled, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), input.type, input.name, input.email, input.phone ?? null, input.message, nowIso());
}

export function markLeadHandled(id: string, handled: boolean) {
  db().prepare("UPDATE volunteer_leads SET handled = ? WHERE id = ?").run(handled ? 1 : 0, id);
}

'@ | Set-Content -LiteralPath "src/lib/repo.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
  scholarshipInterest: z.boolean(),
  currentEducationLevel: z.enum(["shs_graduate", "tertiary", "graduate", "other"]),
});

export const freeRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  schoolName: z.string().min(2, "Enter your school's name"),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
});

export const setPasswordSchema = z
  .object({
    token: z.string().min(1),
    password: z.string().min(8, "Password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

export const loginSchema = z.object({
  email: z.string().email("Enter a valid email address"),
  password: z.string().min(1, "Enter your password"),
});

export const siteContentSchema = z.object({
  orgName: z.string().min(1),
  tagline: z.string().min(1),
  mission: z.string().min(1),
  vision: z.string().min(1),
  contactEmail: z.string().email(),
  contactPhone: z.string().optional().default(""),
  address: z.string().optional().default(""),
  donateInfo: z.string().optional().default(""),
  logoUrl: z.string().optional().default(""),
  caretakingInfo: z.string().optional().default(""),
});

export const staffSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const boardMemberSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  photoUrl: z.string().optional().default(""),
});

export const noteSchema = z.object({
  text: z.string().optional().default(""),
});

export const createStaffUserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  username: z.string().min(3),
  title: z.string().min(1),
  bio: z.string().optional().default(""),
  tempPassword: z.string().min(8),
});

export const blogPostSchema = z.object({
  title: z.string().min(3, "Title is required"),
  excerpt: z.string().min(1, "Add a short excerpt for search results and previews"),
  body: z.string().min(1, "Post body cannot be empty"),
  coverImageUrl: z.string().optional().default(""),
  tags: z.array(z.string()).default([]),
  authorName: z.string().min(1, "Author name is required"),
  published: z.boolean(),
});

export const impactStorySchema = z.object({
  studentName: z.string().min(1, "Student name is required"),
  headline: z.string().min(1, "Headline is required"),
  story: z.string().min(1, "Story text is required"),
  photoUrl: z.string().optional().default(""),
  destinationCountry: z.string().min(1, "Destination is required"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  featured: z.boolean(),
});

export const leadSchema = z.object({
  type: z.enum(["volunteer", "donate", "apply_interest"]),
  name: z.string().min(2, "Enter your name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().optional().default(""),
  message: z.string().min(1, "Please add a short message"),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Enter your current password"),
    newPassword: z.string().min(8, "New password must be at least 8 characters"),
    confirmPassword: z.string().min(8),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "New passwords do not match",
    path: ["confirmPassword"],
  });

'@ | Set-Content -LiteralPath "src/lib/validators.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import {
  getStaffByUserId,
  getStudentById,
  updateStudentStatus,
  updateStudentDocuments,
  addNote,
} from "@/lib/repo";
import { noteSchema } from "@/lib/validators";
import { saveUploadedImage, UploadError } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";

async function requireOwningStaff(studentId: string) {
  const session = await getSession();
  if (!session || session.role !== "staff") {
    throw new Error("Not authorized");
  }
  const staff = getStaffByUserId(session.userId);
  const student = getStudentById(studentId);
  if (!staff || !student || student.assignedStaffId !== staff.id) {
    throw new Error("Not authorized for this student");
  }
  return { session, staff, student };
}

export async function staffUpdateStatusAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  await requireOwningStaff(studentId);
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);
  revalidatePath(`/staff/students/${studentId}`);
  revalidatePath("/staff");
}

export async function staffToggleDocumentAction(formData: FormData) {
  const studentId = String(formData.get("studentId") || "");
  const index = Number(formData.get("index") || 0);
  const { student } = await requireOwningStaff(studentId);
  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (docs[index]) {
    docs[index] = { ...docs[index], done: !docs[index].done };
  }
  updateStudentDocuments(studentId, docs);
  revalidatePath(`/staff/students/${studentId}`);
}

export async function staffAddNoteAction(
  studentId: string,
  _prev: FormState,
  formData: FormData
): Promise<FormState> {
  const { session } = await requireOwningStaff(studentId);
  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const imageFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (imageFile instanceof File && imageFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedImage(imageFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a note or attach a picture." };
  }

  addNote(studentId, session.userId, parsed.data.text.trim(), attachmentUrl);
  revalidatePath(`/staff/students/${studentId}`);
  return { success: "Note added." };
}

'@ | Set-Content -LiteralPath "src/app/actions/staff.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { redirect } from "next/navigation";
import { randomBytes } from "node:crypto";
import bcrypt from "bcryptjs";
import { registerSchema, freeRegisterSchema, loginSchema } from "@/lib/validators";
import {
  createUser,
  getUserByEmail,
  getUserByUsername,
  createStudentForUser,
  createVerificationToken,
  getVerificationToken,
  markEmailVerified,
  setUserPassword,
  getUserById,
  consumeVerificationToken,
} from "@/lib/repo";
import { sendVerificationEmail } from "@/lib/email";
import { createSessionToken, setSessionCookie, clearSessionCookie } from "@/lib/auth";

export type FormState = { error?: string; success?: string };

function slugifyUsername(name: string, email: string): string {
  const base = name.trim().toLowerCase().replace(/[^a-z0-9]+/g, ".").replace(/(^\.|\.$)/g, "");
  return base || email.split("@")[0];
}

async function createAccountAndSendVerification(name: string, email: string) {
  let username = slugifyUsername(name, email);
  let suffix = 0;
  while (true) {
    const candidate = suffix === 0 ? username : `${username}${suffix}`;
    if (!getUserByUsername(candidate)) {
      username = candidate;
      break;
    }
    suffix += 1;
  }

  const user = createUser({
    username,
    email,
    name,
    role: "student",
    passwordHash: null,
    emailVerified: false,
  });

  const token = randomBytes(24).toString("hex");
  createVerificationToken(user.id, token);

  const appUrl = process.env.APP_URL || "http://localhost:3000";
  await sendVerificationEmail(user.email, user.name, `${appUrl}/verify?token=${token}`);

  return user;
}

export async function registerAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = {
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    targetLevel: String(formData.get("targetLevel") || "undergrad"),
    targetCountries: formData.getAll("targetCountries").map(String),
    scholarshipInterest: formData.get("scholarshipInterest") === "on",
    currentEducationLevel: String(formData.get("currentEducationLevel") || "other"),
  };

  const parsed = registerSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form and try again." };
  }

  if (getUserByEmail(parsed.data.email)) {
    return { error: "An account with this email already exists. Try logging in instead." };
  }

  const user = await createAccountAndSendVerification(parsed.data.name, parsed.data.email);

  createStudentForUser({
    userId: user.id,
    targetLevel: parsed.data.targetLevel as "undergrad" | "masters" | "phd",
    targetCountries: parsed.data.targetCountries,
    scholarshipInterest: parsed.data.scholarshipInterest,
    currentEducationLevel: parsed.data.currentEducationLevel,
    applicationType: "standard",
  });

  redirect(`/register/check-email?email=${encodeURIComponent(user.email)}`);
}

export async function registerFreeAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = {
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    schoolName: String(formData.get("schoolName") || ""),
    targetCountries: formData.getAll("targetCountries").map(String),
  };

  const parsed = freeRegisterSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form and try again." };
  }

  if (getUserByEmail(parsed.data.email)) {
    return { error: "An account with this email already exists. Try logging in instead." };
  }

  const user = await createAccountAndSendVerification(parsed.data.name, parsed.data.email);

  createStudentForUser({
    userId: user.id,
    targetLevel: "undergrad",
    targetCountries: parsed.data.targetCountries,
    scholarshipInterest: true,
    currentEducationLevel: "shs_current",
    schoolName: parsed.data.schoolName,
    applicationType: "free_shs",
  });

  redirect(`/register/check-email?email=${encodeURIComponent(user.email)}`);
}

export async function setPasswordAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const token = String(formData.get("token") || "");
  const password = String(formData.get("password") || "");
  const confirmPassword = String(formData.get("confirmPassword") || "");

  if (password.length < 8) {
    return { error: "Password must be at least 8 characters." };
  }
  if (password !== confirmPassword) {
    return { error: "Passwords do not match." };
  }

  const record = getVerificationToken(token);
  if (!record || record.used || new Date(record.expiresAt) < new Date()) {
    return { error: "This verification link is invalid or has expired. Please register again." };
  }

  const user = getUserById(record.userId);
  if (!user) {
    return { error: "We couldn't find that account." };
  }

  const passwordHash = await bcrypt.hash(password, 10);
  setUserPassword(user.id, passwordHash);
  markEmailVerified(user.id);
  consumeVerificationToken(token);

  const session = await createSessionToken({ userId: user.id, role: "student", name: user.name });
  await setSessionCookie(session);

  redirect("/student");
}

export async function loginAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const raw = { email: String(formData.get("email") || ""), password: String(formData.get("password") || "") };
  const parsed = loginSchema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check your details." };
  }

  const user = getUserByEmail(parsed.data.email);
  if (!user || !user.passwordHash) {
    return { error: "Incorrect email or password." };
  }

  const valid = await bcrypt.compare(parsed.data.password, user.passwordHash);
  if (!valid) {
    return { error: "Incorrect email or password." };
  }

  const session = await createSessionToken({ userId: user.id, role: user.role, name: user.name });
  await setSessionCookie(session);

  redirect(`/${user.role}`);
}

export async function logoutAction() {
  await clearSessionCookie();
  redirect("/login");
}

'@ | Set-Content -LiteralPath "src/app/actions/auth.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { getStudentByUserId, updateStudentDocuments, addNote } from "@/lib/repo";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, saveUploadedImage, UploadError, deleteUploadedImage } from "@/lib/uploads";
import type { FormState } from "@/app/actions/auth";
import type { DocumentItem } from "@/types";
export type { FormState } from "@/app/actions/auth";

async function requireOwnStudentRecord() {
  const session = await getSession();
  if (!session || session.role !== "student") {
    throw new Error("Not authorized");
  }
  const student = getStudentByUserId(session.userId);
  if (!student) {
    throw new Error("No application record found");
  }
  return { session, student };
}

export async function studentUploadDocumentAction(formData: FormData): Promise<FormState> {
  const { student } = await requireOwnStudentRecord();
  const index = Number(formData.get("index") || -1);
  const file = formData.get("file");

  if (!(file instanceof File) || file.size === 0) {
    return { error: "Please choose a file first." };
  }

  const docs = JSON.parse(student.documents) as DocumentItem[];
  if (!docs[index]) {
    return { error: "That document slot doesn't exist." };
  }

  let fileUrl: string;
  try {
    fileUrl = await saveUploadedDocument(file);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
  }

  if (docs[index].fileUrl) await deleteUploadedImage(docs[index].fileUrl);

  docs[index] = { ...docs[index], fileUrl, done: true, uploadedAt: new Date().toISOString() };
  updateStudentDocuments(student.id, docs);
  revalidatePath("/student");
  return { success: "Document uploaded." };
}

export async function studentAddNoteAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const imageFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (imageFile instanceof File && imageFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedImage(imageFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a message or attach a picture." };
  }

  addNote(student.id, session.userId, parsed.data.text.trim(), attachmentUrl);
  revalidatePath("/student");
  return { success: "Message sent." };
}

'@ | Set-Content -LiteralPath "src/app/actions/student.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
import type { Role } from "@/types";

export interface ThreadMessage {
  id: string;
  text: string;
  attachmentUrl: string | null;
  authorName: string;
  authorRole: Role;
  createdAt: string;
}

export function MessageThread({ messages, viewerRole }: { messages: ThreadMessage[]; viewerRole: Role }) {
  if (messages.length === 0) {
    return <p className="text-sm text-ink/50 italic">No messages yet.</p>;
  }

  return (
    <div className="space-y-4">
      {messages.map((m) => {
        const isMine = m.authorRole === viewerRole;
        return (
          <div key={m.id} className={`flex ${isMine ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-md rounded-xl px-4 py-3 ${
                isMine ? "bg-ink text-paper" : "bg-paper-dim border border-line"
              }`}
            >
              <p className={`text-xs mb-1 ${isMine ? "text-paper/60" : "text-ink/50"}`}>
                {isMine ? "You" : m.authorName} · {new Date(m.createdAt).toLocaleString()}
              </p>
              {m.text && <p className="text-sm whitespace-pre-line">{m.text}</p>}
              {m.attachmentUrl && (
                <a href={m.attachmentUrl} target="_blank" rel="noopener noreferrer" className="block mt-2">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={m.attachmentUrl}
                    alt="Attachment"
                    className="rounded-lg max-h-64 border border-black/10"
                  />
                </a>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/components/message-thread.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useActionState, useRef, useState } from "react";
import type { FormState } from "@/app/actions/auth";

export function MessageForm({
  action,
  placeholder,
}: {
  action: (prevState: FormState, formData: FormData) => Promise<FormState>;
  placeholder: string;
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(action, {});
  const [preview, setPreview] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      action={async (formData) => {
        await formAction(formData);
        formRef.current?.reset();
        setPreview(null);
      }}
      className="space-y-3"
    >
      <textarea name="text" rows={2} placeholder={placeholder} className="input" />

      {preview && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={preview} alt="Attachment preview" className="h-20 rounded-lg border border-line" />
      )}

      <div className="flex items-center justify-between gap-3">
        <label className="text-sm text-teal hover:underline cursor-pointer">
          {preview ? "Change picture" : "+ Attach a picture"}
          <input
            ref={fileRef}
            type="file"
            name="image"
            accept="image/jpeg,image/png,image/webp,image/gif"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (!file) return;
              const reader = new FileReader();
              reader.onload = () => setPreview(reader.result as string);
              reader.readAsDataURL(file);
            }}
          />
        </label>
        <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
          {pending ? "Sending..." : "Send"}
        </button>
      </div>

      {state.error && <p className="text-sm text-red-700">{state.error}</p>}
    </form>
  );
}

'@ | Set-Content -LiteralPath "src/components/message-form.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useState } from "react";

export function PhotoLightbox({ src, alt, className }: { src: string; alt: string; className?: string }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button type="button" onClick={() => setOpen(true)} className="block w-full h-full cursor-zoom-in">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={src} alt={alt} className={className} />
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 bg-ink/90 flex items-center justify-center p-6 cursor-zoom-out"
          onClick={() => setOpen(false)}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={src} alt={alt} className="max-w-full max-h-full rounded-lg object-contain" />
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="absolute top-6 right-6 text-paper text-3xl leading-none"
            aria-label="Close"
          >
            ×
          </button>
        </div>
      )}
    </>
  );
}

'@ | Set-Content -LiteralPath "src/components/photo-lightbox.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useRef, useState } from "react";

export function PhotoUploadField({
  existingUrl,
  name = "photo",
  hiddenFieldName = "existingPhotoUrl",
  shape = "circle",
}: {
  existingUrl?: string | null;
  name?: string;
  hiddenFieldName?: string;
  shape?: "circle" | "rect";
}) {
  const [preview, setPreview] = useState<string | null>(existingUrl || null);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  function handleFiles(files: FileList | null) {
    const file = files?.[0];
    if (!file) return;
    if (inputRef.current) {
      const dt = new DataTransfer();
      dt.items.add(file);
      inputRef.current.files = dt.files;
    }
    const reader = new FileReader();
    reader.onload = () => setPreview(reader.result as string);
    reader.readAsDataURL(file);
  }

  return (
    <div>
      <input type="hidden" name={hiddenFieldName} value={existingUrl ?? ""} />
      <div
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          handleFiles(e.dataTransfer.files);
        }}
        onClick={() => inputRef.current?.click()}
        className={`flex items-center gap-4 border-2 border-dashed rounded-xl p-4 cursor-pointer transition-colors ${
          dragging ? "border-teal bg-teal/5" : "border-line hover:border-teal/60"
        }`}
      >
        <div
          className={`bg-paper-dim border border-line grid place-items-center overflow-hidden shrink-0 ${
            shape === "circle" ? "w-24 h-24 rounded-full" : "w-32 h-20 rounded-lg"
          }`}
        >
          {preview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={preview} alt="Preview" className="w-full h-full object-cover" />
          ) : (
            <span className="text-xs text-ink/40">No photo</span>
          )}
        </div>
        <div className="text-sm">
          <p className="text-ink">
            <span className="text-teal">Click to upload</span> or drag and drop
          </p>
          <p className="text-ink/50 text-xs mt-0.5">JPG, PNG, WEBP, or GIF — up to 5MB</p>
        </div>
      </div>
      <input
        ref={inputRef}
        type="file"
        name={name}
        accept="image/jpeg,image/png,image/webp,image/gif"
        onChange={(e) => handleFiles(e.target.files)}
        className="hidden"
      />
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/components/photo-upload-field.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
@'
import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";
import { DocumentUploadRow } from "./document-upload-row";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { studentAddNoteAction } from "@/app/actions/student";

export const dynamic = "force-dynamic";

export default async function StudentHomePage() {
  const session = await getSession();
  const student = session ? getStudentByUserId(session.userId) : undefined;

  if (!student) {
    return <p className="text-ink/60">We couldn't find your application record. Please contact WorldPath Group.</p>;
  }

  const staff = student.assignedStaffId ? getStaffById(student.assignedStaffId) : undefined;
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === student.status)?.label ?? student.status;
  const completedDocs = documents.filter((d) => d.done).length;

  return (
    <div>
      <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-3">
        {student.code}
      </p>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
        {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet — one will be soon."}
      </p>

      <div className="grid sm:grid-cols-2 gap-6 mb-10">
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Application status</p>
          <p className="font-display text-xl text-gold-deep">{statusLabel}</p>
        </div>
        <div className="border border-line rounded-xl p-5">
          <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">Targeting</p>
          <p className="capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      <div className="mb-10">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display text-xl">Document checklist</h2>
          <span className="text-sm text-ink/50">
            {completedDocs}/{documents.length} complete
          </span>
        </div>
        <p className="text-xs text-ink/50 mb-3">
          Upload a photo or PDF of each document. Uploading automatically marks it complete.
        </p>
        <ul className="space-y-2">
          {documents.map((doc, index) => (
            <DocumentUploadRow key={doc.name} doc={doc} index={index} />
          ))}
        </ul>
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Messages with your counselor</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="student"
          />
        </div>
        <MessageForm action={studentAddNoteAction} placeholder="Send a message to your counselor..." />
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/student/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
@'
"use client";

import { useRef, useState, useTransition } from "react";
import { studentUploadDocumentAction } from "@/app/actions/student";
import type { DocumentItem } from "@/types";

export function DocumentUploadRow({ doc, index }: { doc: DocumentItem; index: number }) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    const formData = new FormData();
    formData.set("index", String(index));
    formData.set("file", file);
    startTransition(async () => {
      const result = await studentUploadDocumentAction(formData);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <li className="border border-line rounded-lg px-3 py-2.5">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <span
            className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
              doc.done ? "bg-teal border-teal text-white" : "border-line"
            }`}
          >
            {doc.done ? "✓" : ""}
          </span>
          <span className={`text-sm truncate ${doc.done ? "" : "text-ink/80"}`}>{doc.name}</span>
        </div>
        <div className="flex items-center gap-3 shrink-0 text-xs">
          {doc.fileUrl && (
            <a href={doc.fileUrl} target="_blank" rel="noopener noreferrer" className="text-teal hover:underline">
              View
            </a>
          )}
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            disabled={pending}
            className="text-teal hover:underline disabled:opacity-60"
          >
            {pending ? "Uploading..." : doc.fileUrl ? "Replace" : "Upload"}
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif,application/pdf"
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0])}
          />
        </div>
      </div>
      {error && <p className="text-xs text-red-700 mt-1.5">{error}</p>}
    </li>
  );
}

'@ | Set-Content -LiteralPath "src/app/student/document-upload-row.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
@'
"use client";

import { staffToggleDocumentAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export function DocumentChecklist({ studentId, documents }: { studentId: string; documents: DocumentItem[] }) {
  return (
    <ul className="space-y-2">
      {documents.map((doc, index) => (
        <li key={doc.name} className="flex items-center gap-2">
          <form action={staffToggleDocumentAction} className="flex-1">
            <input type="hidden" name="studentId" value={studentId} />
            <input type="hidden" name="index" value={index} />
            <button
              type="submit"
              className="w-full flex items-center gap-3 border border-line rounded-lg px-3 py-2 text-sm hover:border-ink transition-colors text-left"
            >
              <span
                className={`w-4 h-4 rounded border grid place-items-center text-[10px] shrink-0 ${
                  doc.done ? "bg-teal border-teal text-white" : "border-line"
                }`}
              >
                {doc.done ? "✓" : ""}
              </span>
              <span className={`truncate ${doc.done ? "line-through text-ink/50" : ""}`}>{doc.name}</span>
            </button>
          </form>
          {doc.fileUrl && (
            <a
              href={doc.fileUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-teal hover:underline shrink-0"
            >
              View file
            </a>
          )}
        </li>
      ))}
    </ul>
  );
}

'@ | Set-Content -LiteralPath "src/app/staff/students/[id]/document-checklist.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/staff/students/[id]" | Out-Null
@'
import { notFound } from "next/navigation";
import { getSession } from "@/lib/auth";
import { getStaffByUserId, getStudentById, getUserById, listNotesForStudent } from "@/lib/repo";
import { StatusSelect } from "./status-select";
import { DocumentChecklist } from "./document-checklist";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { staffAddNoteAction } from "@/app/actions/staff";
import type { DocumentItem } from "@/types";

export const dynamic = "force-dynamic";

export default async function StaffStudentPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const session = await getSession();
  const staff = session ? getStaffByUserId(session.userId) : undefined;
  const student = getStudentById(id);

  if (!student || !staff || student.assignedStaffId !== staff.id) notFound();

  const user = getUserById(student.userId);
  const notes = listNotesForStudent(student.id);
  const documents = JSON.parse(student.documents) as DocumentItem[];
  const targetCountries = JSON.parse(student.targetCountries) as string[];
  const addNote = staffAddNoteAction.bind(null, student.id);

  return (
    <div className="max-w-3xl">
      <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block mb-3">
        {student.code}
      </p>
      <h1 className="font-display text-3xl mb-1">{user?.name}</h1>
      <p className="text-ink/60 mb-8">{user?.email}</p>

      <div className="grid sm:grid-cols-2 gap-8 mb-10">
        <div>
          <h2 className="text-sm font-medium mb-2">Application status</h2>
          <StatusSelect studentId={student.id} status={student.status} />
        </div>
        <div>
          <h2 className="text-sm font-medium mb-2">Targeting</h2>
          <p className="text-sm text-ink/70 capitalize">{student.targetLevel}</p>
          <p className="text-sm text-ink/70">{targetCountries.join(", ")}</p>
        </div>
      </div>

      <div className="mb-10">
        <h2 className="font-display text-xl mb-4">Document checklist</h2>
        <DocumentChecklist studentId={student.id} documents={documents} />
      </div>

      <div>
        <h2 className="font-display text-xl mb-4">Messages</h2>
        <div className="border border-line rounded-xl p-5 mb-4 max-h-96 overflow-y-auto">
          <MessageThread
            messages={notes.map((n) => ({
              id: n.id,
              text: n.text,
              attachmentUrl: n.attachmentUrl,
              authorName: n.authorName,
              authorRole: n.authorRole,
              createdAt: n.createdAt,
            }))}
            viewerRole="staff"
          />
        </div>
        <MessageForm action={addNote} placeholder="Send a message to this student..." />
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/staff/students/[id]/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/about" | Out-Null
@'
import { getSiteContent, listStaff, listBoardMembers } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AboutPage() {
  const content = getSiteContent();
  const staff = listStaff();
  const board = listBoardMembers();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">About us</p>
          <h1 className="font-display text-4xl mt-4 max-w-2xl">Who's behind {content.orgName}</h1>
          <p className="mt-6 text-lg text-ink/80 max-w-2xl">{content.mission}</p>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-teal font-medium mb-2">Day to day</p>
          <h2 className="font-display text-2xl mb-8">Staff directory</h2>
          {staff.length === 0 ? (
            <EmptyNote text="Staff profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {staff.map((s) => (
                <PersonCard key={s.id} name={s.name} title={s.title} bio={s.bio} photoUrl={s.photoUrl} variant="staff" />
              ))}
            </div>
          )}
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 border-t border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-2">Governance</p>
          <h2 className="font-display text-2xl mb-8">Board of Directors</h2>
          {board.length === 0 ? (
            <EmptyNote text="Board member profiles will appear here once added from the admin portal." />
          ) : (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {board.map((b) => (
                <PersonCard key={b.id} name={b.name} title={b.title} bio={b.bio} photoUrl={b.photoUrl} variant="board" />
              ))}
            </div>
          )}
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

function PersonCard({
  name,
  title,
  bio,
  photoUrl,
  variant,
}: {
  name: string;
  title: string;
  bio: string;
  photoUrl: string | null;
  variant: "staff" | "board";
}) {
  const isBoard = variant === "board";
  return (
    <div
      className={`rounded-xl p-6 border ${
        isBoard ? "border-gold-deep/30 bg-gold/5" : "border-line"
      }`}
    >
      <div className="w-20 h-20 rounded-full bg-paper-dim border border-line overflow-hidden mb-4">
        {photoUrl ? (
          <PhotoLightbox src={photoUrl} alt={name} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full grid place-items-center">
            <span className="font-display text-2xl">{name.charAt(0)}</span>
          </div>
        )}
      </div>
      <h3 className="font-display text-lg">{name}</h3>
      <p className={`text-sm mb-2 ${isBoard ? "text-gold-deep" : "text-teal"}`}>
        {isBoard ? "Board · " : ""}
        {title}
      </p>
      <p className="text-sm text-ink/70 leading-relaxed">{bio}</p>
    </div>
  );
}

function EmptyNote({ text }: { text: string }) {
  return <p className="text-sm text-ink/50 italic border border-dashed border-line rounded-xl p-6">{text}</p>;
}

'@ | Set-Content -LiteralPath "src/app/about/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin/staff" | Out-Null
@'
import Link from "next/link";
import { listStaff } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteStaffAction } from "@/app/actions/admin";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AdminStaffPage() {
  const staff = listStaff();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Staff directory</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/staff/new" className="btn-primary">
          + Add staff
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {staff.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No staff members yet.</p>}
        {staff.map((s) => (
          <div key={s.id} className="p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
              {s.photoUrl ? (
                <PhotoLightbox src={s.photoUrl} alt={s.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full grid place-items-center text-xs text-ink/40">{s.name.charAt(0)}</div>
              )}
            </div>
            <div className="flex-1">
              <p className="font-medium">{s.name}</p>
              <p className="text-sm text-ink/60">{s.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/staff/${s.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={s.id} action={deleteStaffAction} confirmLabel={`Remove ${s.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/staff/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin/board" | Out-Null
@'
import Link from "next/link";
import { listBoardMembers } from "@/lib/repo";
import { DeleteButton } from "@/components/delete-button";
import { deleteBoardMemberAction } from "@/app/actions/admin";
import { PhotoLightbox } from "@/components/photo-lightbox";

export const dynamic = "force-dynamic";

export default function AdminBoardPage() {
  const board = listBoardMembers();

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-3xl mb-2">Board of Directors</h1>
          <p className="text-ink/60">Shown publicly on the About page.</p>
        </div>
        <Link href="/admin/board/new" className="btn-primary">
          + Add member
        </Link>
      </div>

      <div className="divide-y divide-line border border-line rounded-xl">
        {board.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No board members yet.</p>}
        {board.map((b) => (
          <div key={b.id} className="p-4 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
              {b.photoUrl ? (
                <PhotoLightbox src={b.photoUrl} alt={b.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full grid place-items-center text-xs text-ink/40">{b.name.charAt(0)}</div>
              )}
            </div>
            <div className="flex-1">
              <p className="font-medium">{b.name}</p>
              <p className="text-sm text-ink/60">{b.title}</p>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <Link href={`/admin/board/${b.id}`} className="text-teal hover:underline">
                Edit
              </Link>
              <DeleteButton id={b.id} action={deleteBoardMemberAction} confirmLabel={`Remove ${b.name}?`} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/board/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/register" | Out-Null
@'
"use client";

import { useActionState } from "react";
import Link from "next/link";
import { registerAction, type FormState } from "@/app/actions/auth";
import { TARGET_LEVELS, TARGET_COUNTRIES, CURRENT_EDUCATION_LEVELS } from "@/types";

const initialState: FormState = {};

export default function RegisterPage() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Get started</p>
        <h1 className="font-display text-3xl mt-3 mb-2">Create your student account</h1>
        <p className="text-sm text-ink/70 mb-6">
          You'll get a WorldPath student code and a link to verify your email and set a password.
        </p>

        <div className="mb-8 rounded-xl border border-gold-deep/30 bg-gold/5 px-4 py-3 text-sm">
          Currently a Senior High School student?{" "}
          <Link href="/register/free" className="text-gold-deep font-medium hover:underline">
            Apply through our free application program →
          </Link>
        </div>

        <form action={formAction} className="space-y-5">
          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Ama Serwaa Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="What are you applying for?">
            <select name="targetLevel" className="input" defaultValue="undergrad">
              {TARGET_LEVELS.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </Field>

          <Field label="Your current education level">
            <select name="currentEducationLevel" className="input" defaultValue="tertiary">
              {CURRENT_EDUCATION_LEVELS.map((l) => (
                <option key={l.value} value={l.value}>
                  {l.label}
                </option>
              ))}
            </select>
          </Field>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="scholarshipInterest" defaultChecked className="accent-teal" />
            I'm interested in scholarship / financial aid support
          </label>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Create account"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Already registered?{" "}
          <Link href="/login" className="text-teal hover:underline">
            Log in
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}

'@ | Set-Content -LiteralPath "src/app/register/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/register/free" | Out-Null
@'
"use client";

import { useActionState } from "react";
import Link from "next/link";
import { registerFreeAction, type FormState } from "@/app/actions/auth";
import { TARGET_COUNTRIES } from "@/types";

const initialState: FormState = {};

export default function FreeRegisterPage() {
  const [state, formAction, pending] = useActionState(registerFreeAction, initialState);

  return (
    <main className="flex-1 flex items-start justify-center py-16 px-6">
      <div className="w-full max-w-lg">
        <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Free application program</p>
        <h1 className="font-display text-3xl mt-3 mb-2">For current Senior High School students</h1>
        <p className="text-sm text-ink/70 mb-8">
          Through our partnership with Wesley Senior High School, current SHS students get full
          undergraduate application support at no cost. You'll get a WorldPath student code and a
          link to verify your email and set a password.
        </p>

        <form action={formAction} className="space-y-5">
          <Field label="Full name">
            <input name="name" required className="input" placeholder="e.g. Ama Serwaa Owusu" />
          </Field>

          <Field label="Email address">
            <input name="email" type="email" required className="input" placeholder="you@example.com" />
          </Field>

          <Field label="Your school's name">
            <input name="schoolName" required className="input" placeholder="e.g. Wesley Senior High School" />
          </Field>

          <Field label="Destination countries (choose all that interest you)">
            <div className="grid grid-cols-2 gap-2">
              {TARGET_COUNTRIES.map((c) => (
                <label key={c} className="flex items-center gap-2 text-sm border border-line rounded-lg px-3 py-2">
                  <input type="checkbox" name="targetCountries" value={c} className="accent-teal" />
                  {c}
                </label>
              ))}
            </div>
          </Field>

          {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-full bg-ink text-paper px-6 py-3 hover:bg-teal transition-colors disabled:opacity-60"
          >
            {pending ? "Creating account..." : "Apply for free"}
          </button>
        </form>

        <p className="text-sm text-ink/60 mt-6">
          Not currently in Senior High School?{" "}
          <Link href="/register" className="text-teal hover:underline">
            Use the standard application
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block text-sm font-medium mb-1.5">{label}</span>
      {children}
    </label>
  );
}

'@ | Set-Content -LiteralPath "src/app/register/free/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin/students" | Out-Null
@'
import { listStudents, listStaff, getUserById } from "@/lib/repo";
import { StudentRow } from "./student-row";

export const dynamic = "force-dynamic";

export default function AdminStudentsPage() {
  const students = listStudents();
  const staff = listStaff();

  const rows = students.map((s) => {
    const user = getUserById(s.userId);
    return {
      id: s.id,
      code: s.code,
      name: user?.name || "—",
      email: user?.email || "—",
      targetLevel: s.targetLevel,
      status: s.status,
      assignedStaffId: s.assignedStaffId,
      applicationType: s.applicationType,
      schoolName: s.schoolName,
    };
  });

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Students</h1>
      <p className="text-ink/60 mb-8">Every student record across the organization. Changes save instantly.</p>

      <div className="overflow-x-auto border border-line rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-ink/50 border-b border-line">
              <th className="py-3 px-4 font-medium">Code</th>
              <th className="py-3 px-4 font-medium">Student</th>
              <th className="py-3 px-4 font-medium">Program</th>
              <th className="py-3 px-4 font-medium">Level</th>
              <th className="py-3 px-4 font-medium">Status</th>
              <th className="py-3 px-4 font-medium">Assigned staff</th>
            </tr>
          </thead>
          <tbody className="px-4">
            {rows.length === 0 && (
              <tr>
                <td colSpan={6} className="py-6 px-4 text-ink/50 italic">
                  No students have registered yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <StudentRow key={r.id} student={r} staffOptions={staff.map((s) => ({ id: s.id, name: s.name }))} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/students/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin/students" | Out-Null
@'
"use client";

import { useRef } from "react";
import { assignStudentAction, adminUpdateStatusAction } from "@/app/actions/admin";
import { APPLICATION_STATUSES } from "@/types";

export function StudentRow({
  student,
  staffOptions,
}: {
  student: {
    id: string;
    code: string;
    name: string;
    email: string;
    targetLevel: string;
    status: string;
    assignedStaffId: string | null;
    applicationType: string;
    schoolName: string;
  };
  staffOptions: { id: string; name: string }[];
}) {
  const assignFormRef = useRef<HTMLFormElement>(null);
  const statusFormRef = useRef<HTMLFormElement>(null);

  return (
    <tr className="border-b border-line last:border-0">
      <td className="py-3 pl-4 pr-4">
        <span className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1">{student.code}</span>
      </td>
      <td className="py-3 pr-4">
        <p className="font-medium">{student.name}</p>
        <p className="text-xs text-ink/50">{student.email}</p>
      </td>
      <td className="py-3 pr-4">
        {student.applicationType === "free_shs" ? (
          <>
            <span className="text-xs uppercase tracking-wide text-gold-deep font-medium">Free · SHS</span>
            {student.schoolName && <p className="text-xs text-ink/50 mt-0.5">{student.schoolName}</p>}
          </>
        ) : (
          <span className="text-xs text-ink/50">Standard</span>
        )}
      </td>
      <td className="py-3 pr-4 text-sm capitalize">{student.targetLevel}</td>
      <td className="py-3 pr-4">
        <form ref={statusFormRef} action={adminUpdateStatusAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="status"
            defaultValue={student.status}
            className="input py-1.5 text-xs"
            onChange={() => statusFormRef.current?.requestSubmit()}
          >
            {APPLICATION_STATUSES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </form>
      </td>
      <td className="py-3 pr-4">
        <form ref={assignFormRef} action={assignStudentAction}>
          <input type="hidden" name="studentId" value={student.id} />
          <select
            name="staffId"
            defaultValue={student.assignedStaffId ?? ""}
            className="input py-1.5 text-xs"
            onChange={() => assignFormRef.current?.requestSubmit()}
          >
            <option value="">Unassigned</option>
            {staffOptions.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </form>
      </td>
    </tr>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/students/student-row.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
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

'@ | Set-Content -LiteralPath "src/app/opengraph-image.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
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

'@ | Set-Content -LiteralPath "src/app/icon.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/api/uploads/[filename]" | Out-Null
@'
import { NextRequest, NextResponse } from "next/server";
import fs from "node:fs/promises";
import path from "node:path";
import { uploadDir } from "@/lib/uploads";

const CONTENT_TYPES: Record<string, string> = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".pdf": "application/pdf",
};

export async function GET(_request: NextRequest, { params }: { params: Promise<{ filename: string }> }) {
  const { filename } = await params;

  // Guard against path traversal — only allow a bare filename.
  if (!filename || filename.includes("/") || filename.includes("..")) {
    return new NextResponse("Not found", { status: 404 });
  }

  const ext = path.extname(filename).toLowerCase();
  const contentType = CONTENT_TYPES[ext];
  if (!contentType) {
    return new NextResponse("Not found", { status: 404 });
  }

  try {
    const filePath = path.join(uploadDir(), filename);
    const data = await fs.readFile(filePath);
    return new NextResponse(new Uint8Array(data), {
      headers: {
        "Content-Type": contentType,
        "Cache-Control": "public, max-age=31536000, immutable",
      },
    });
  } catch {
    return new NextResponse("Not found", { status: 404 });
  }
}

'@ | Set-Content -LiteralPath "src/app/api/uploads/[filename]/route.ts" -Encoding utf8

git add .
git commit -m "Add document uploads, two-way messaging, photo lightbox, OG image fix, free SHS application"
git push

Write-Host 'Done. Files written and pushed.'