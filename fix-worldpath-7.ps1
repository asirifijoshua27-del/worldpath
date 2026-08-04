# WorldPath Group - CONSOLIDATED fix: hero image upload feature
# (which appears to have not made it in last time) PLUS the full
# homepage credibility redesign. This script is safe to run even if
# some of these files already have this content.
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'

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
    "ALTER TABLE students ADD COLUMN photoUrl TEXT",
    "ALTER TABLE volunteer_leads ADD COLUMN areasOfInterest TEXT NOT NULL DEFAULT '[]'",
    "ALTER TABLE volunteer_leads ADD COLUMN availability TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN heroImageUrl TEXT",
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
  photoUrl: string | null;
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
  heroImageUrl: string | null;
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
  areasOfInterest: string; // JSON-encoded string[], only meaningful for type "volunteer"
  availability: string;
  handled: number;
  createdAt: string;
}

export const VOLUNTEER_AREAS = [
  "Essay review",
  "Mock interviews",
  "Mentoring a student",
  "Fundraising",
  "Event support",
  "Social media / content",
  "Other",
];

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
  photoUrl?: string | null;
}): StudentRecord {
  const id = newId();
  const now = nowIso();
  const code = nextStudentCode();
  db()
    .prepare(
      `INSERT INTO students
        (id, code, userId, targetLevel, targetCountries, status, assignedStaffId, documents, scholarshipInterest, currentEducationLevel, schoolName, applicationType, photoUrl, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?, 'new', NULL, ?, ?, ?, ?, ?, ?, ?, ?)`
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
      input.photoUrl ?? null,
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
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, caretakingInfo = ?
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
      input.heroImageUrl,
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

export function createLead(input: {
  type: LeadType;
  name: string;
  email: string;
  phone?: string;
  message: string;
  areasOfInterest?: string[];
  availability?: string;
}) {
  db()
    .prepare(
      `INSERT INTO volunteer_leads (id, type, name, email, phone, message, areasOfInterest, availability, handled, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(
      newId(),
      input.type,
      input.name,
      input.email,
      input.phone ?? null,
      input.message,
      JSON.stringify(input.areasOfInterest ?? []),
      input.availability ?? "",
      nowIso()
    );
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
  heroImageUrl: z.string().optional().default(""),
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

export const leadSchema = z
  .object({
    type: z.enum(["volunteer", "donate", "apply_interest"]),
    name: z.string().min(2, "Enter your name"),
    email: z.string().email("Enter a valid email address"),
    phone: z.string().optional().default(""),
    message: z.string().optional().default(""),
    areasOfInterest: z.array(z.string()).optional().default([]),
    availability: z.string().optional().default(""),
  })
  .refine((data) => data.type !== "donate" || data.message.trim().length > 0, {
    message: "Please add a short message",
    path: ["message"],
  })
  .refine((data) => data.type !== "volunteer" || data.areasOfInterest.length > 0, {
    message: "Choose at least one area you'd like to help with",
    path: ["areasOfInterest"],
  });

export const adminEmailSchema = z.object({
  subject: z.string().min(1, "Add a subject line"),
  body: z.string().min(1, "Write a message"),
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
import bcrypt from "bcryptjs";
import { getSession } from "@/lib/auth";
import { saveUploadedImage, deleteUploadedImage, UploadError } from "@/lib/uploads";
import { sendAdminEmail, EmailSendError } from "@/lib/email";
import {
  updateSiteContent,
  createStaff,
  updateStaff,
  deleteStaff,
  getStaffById,
  createBoardMember,
  updateBoardMember,
  deleteBoardMember,
  getBoardMemberById,
  assignStudentStaff,
  updateStudentStatus,
  createUser,
  getUserByEmail,
  getUserByUsername,
  getStudentById,
  getUserById,
} from "@/lib/repo";
import {
  siteContentSchema,
  staffSchema,
  boardMemberSchema,
  createStaffUserSchema,
  adminEmailSchema,
} from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

async function requireAdmin() {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  return session;
}

export async function updateSiteContentAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const existingLogoUrl = String(formData.get("existingLogoUrl") || "");
  const logoFile = formData.get("logo");

  let logoUrl = existingLogoUrl;
  if (logoFile instanceof File && logoFile.size > 0) {
    try {
      logoUrl = await saveUploadedImage(logoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingLogoUrl) await deleteUploadedImage(existingLogoUrl);
  }

  const existingHeroImageUrl = String(formData.get("existingHeroImageUrl") || "");
  const heroFile = formData.get("hero");

  let heroImageUrl = existingHeroImageUrl;
  if (heroFile instanceof File && heroFile.size > 0) {
    try {
      heroImageUrl = await saveUploadedImage(heroFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingHeroImageUrl) await deleteUploadedImage(existingHeroImageUrl);
  }

  const parsed = siteContentSchema.safeParse({
    orgName: String(formData.get("orgName") || ""),
    tagline: String(formData.get("tagline") || ""),
    mission: String(formData.get("mission") || ""),
    vision: String(formData.get("vision") || ""),
    contactEmail: String(formData.get("contactEmail") || ""),
    contactPhone: String(formData.get("contactPhone") || ""),
    address: String(formData.get("address") || ""),
    donateInfo: String(formData.get("donateInfo") || ""),
    caretakingInfo: String(formData.get("caretakingInfo") || ""),
    logoUrl,
    heroImageUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  updateSiteContent(parsed.data);
  revalidatePath("/");
  revalidatePath("/about");
  revalidatePath("/impact");
  revalidatePath("/get-involved");
  revalidatePath("/blog");
  revalidatePath("/admin/content");
  return { success: "Site content updated." };
}

export async function saveStaffAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingPhotoUrl = String(formData.get("existingPhotoUrl") || "");
  const photoFile = formData.get("photo");

  let photoUrl = existingPhotoUrl;
  if (photoFile instanceof File && photoFile.size > 0) {
    try {
      photoUrl = await saveUploadedImage(photoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingPhotoUrl) await deleteUploadedImage(existingPhotoUrl);
  }

  const parsed = staffSchema.safeParse({
    name: String(formData.get("name") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    photoUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (id) {
    updateStaff(id, parsed.data);
  } else {
    createStaff(parsed.data);
  }
  revalidatePath("/admin/staff");
  revalidatePath("/about");
  return { success: "Staff profile saved." };
}

export async function deleteStaffAction(id: string) {
  await requireAdmin();
  const staff = getStaffById(id);
  deleteStaff(id);
  await deleteUploadedImage(staff?.photoUrl);
  revalidatePath("/admin/staff");
  revalidatePath("/about");
}

export async function saveBoardMemberAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const id = String(formData.get("id") || "");
  const existingPhotoUrl = String(formData.get("existingPhotoUrl") || "");
  const photoFile = formData.get("photo");

  let photoUrl = existingPhotoUrl;
  if (photoFile instanceof File && photoFile.size > 0) {
    try {
      photoUrl = await saveUploadedImage(photoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingPhotoUrl) await deleteUploadedImage(existingPhotoUrl);
  }

  const parsed = boardMemberSchema.safeParse({
    name: String(formData.get("name") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    photoUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (id) {
    updateBoardMember(id, parsed.data);
  } else {
    createBoardMember(parsed.data);
  }
  revalidatePath("/admin/board");
  revalidatePath("/about");
  return { success: "Board member saved." };
}

export async function deleteBoardMemberAction(id: string) {
  await requireAdmin();
  const member = getBoardMemberById(id);
  deleteBoardMember(id);
  await deleteUploadedImage(member?.photoUrl);
  revalidatePath("/admin/board");
  revalidatePath("/about");
}

export async function assignStudentAction(formData: FormData) {
  await requireAdmin();
  const studentId = String(formData.get("studentId") || "");
  const staffId = String(formData.get("staffId") || "");
  assignStudentStaff(studentId, staffId || null);
  revalidatePath("/admin/students");
}

export async function adminUpdateStatusAction(formData: FormData) {
  await requireAdmin();
  const studentId = String(formData.get("studentId") || "");
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);
  revalidatePath("/admin/students");
}

export async function createStaffUserAction(_prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();
  const parsed = createStaffUserSchema.safeParse({
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    username: String(formData.get("username") || ""),
    title: String(formData.get("title") || ""),
    bio: String(formData.get("bio") || ""),
    tempPassword: String(formData.get("tempPassword") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  if (getUserByEmail(parsed.data.email)) {
    return { error: "A user with this email already exists." };
  }
  if (getUserByUsername(parsed.data.username)) {
    return { error: "That username is taken." };
  }
  const passwordHash = await bcrypt.hash(parsed.data.tempPassword, 10);
  const user = createUser({
    username: parsed.data.username,
    email: parsed.data.email,
    name: parsed.data.name,
    role: "staff",
    passwordHash,
    emailVerified: true,
  });
  createStaff({ userId: user.id, name: parsed.data.name, title: parsed.data.title, bio: parsed.data.bio });
  revalidatePath("/admin/users");
  revalidatePath("/admin/staff");
  return { success: `Staff account created for ${parsed.data.name}. Share the temporary password securely.` };
}

export async function emailStudentAction(studentId: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const student = getStudentById(studentId);
  if (!student) {
    return { error: "Student not found." };
  }
  const user = getUserById(student.userId);
  if (!user) {
    return { error: "Student's account not found." };
  }

  const parsed = adminEmailSchema.safeParse({
    subject: String(formData.get("subject") || ""),
    body: String(formData.get("body") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  try {
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body);
  } catch (e) {
    if (e instanceof EmailSendError) return { error: e.message };
    throw e;
  }

  return { success: `Email sent to ${user.email}.` };
}

'@ | Set-Content -LiteralPath "src/app/actions/admin.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin/content" | Out-Null
@'
"use client";

import { useActionState } from "react";
import { updateSiteContentAction, type FormState } from "@/app/actions/admin";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function ContentForm({
  content,
}: {
  content: {
    orgName: string;
    tagline: string;
    mission: string;
    vision: string;
    contactEmail: string;
    contactPhone: string;
    address: string;
    donateInfo: string;
    logoUrl: string | null;
    heroImageUrl: string | null;
    caretakingInfo: string;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateSiteContentAction, {});

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      <div>
        <span className="block text-sm font-medium mb-1.5">Logo (shown in the site header)</span>
        <PhotoUploadField existingUrl={content.logoUrl} name="logo" hiddenFieldName="existingLogoUrl" />
      </div>

      <div>
        <span className="block text-sm font-medium mb-1.5">
          Homepage hero background (the dark banner behind the headline)
        </span>
        <PhotoUploadField
          existingUrl={content.heroImageUrl}
          name="hero"
          hiddenFieldName="existingHeroImageUrl"
          shape="rect"
        />
        <p className="text-xs text-ink/50 mt-1.5">
          A wide photo works best. It's shown with a dark overlay so the headline text stays readable.
          Leave empty to keep the plain navy background.
        </p>
      </div>

      <Field label="Organization name">
        <input name="orgName" defaultValue={content.orgName} required className="input" />
      </Field>
      <Field label="Tagline">
        <input name="tagline" defaultValue={content.tagline} required className="input" />
      </Field>
      <Field label="Mission">
        <textarea name="mission" defaultValue={content.mission} required rows={4} className="input" />
      </Field>
      <Field label="Vision">
        <textarea name="vision" defaultValue={content.vision} required rows={3} className="input" />
      </Field>
      <Field label="WorldPath Caretaking Foundation (projects, partnerships — shown on the homepage)">
        <textarea
          name="caretakingInfo"
          defaultValue={content.caretakingInfo}
          rows={5}
          className="input"
          placeholder="Describe your caretaking projects and partnerships, e.g. work with God Matters Fellowship..."
        />
      </Field>
      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Contact email">
          <input name="contactEmail" type="email" defaultValue={content.contactEmail} required className="input" />
        </Field>
        <Field label="Contact phone (one or more, any format)">
          <input name="contactPhone" defaultValue={content.contactPhone} className="input" placeholder="e.g. 0530901898 / 0509878889" />
        </Field>
      </div>
      <Field label="Address (one location per line)">
        <textarea
          name="address"
          defaultValue={content.address}
          rows={3}
          className="input"
          placeholder={"Konongo\nP.O. Box 87\nAccra, Legon"}
        />
      </Field>
      <Field label="Donate details (bank account / mobile money — shown on the Get Involved page)">
        <textarea name="donateInfo" defaultValue={content.donateInfo} rows={4} className="input" />
      </Field>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Save changes"}
      </button>
    </form>
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

'@ | Set-Content -LiteralPath "src/app/admin/content/content-form.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.APP_URL || "http://localhost:3000"),
  title: {
    default: "WorldPath Group | University & Scholarship Applications",
    template: "%s | WorldPath Group",
  },
  description:
    "WorldPath Group helps talented Ghanaian students apply to universities and scholarships in the USA, Canada, UK, Germany, and Asia.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <head>
        <meta charSet="utf-8" />
      </head>
      <body className="min-h-full flex flex-col bg-paper text-ink">{children}</body>
    </html>
  );
}

'@ | Set-Content -LiteralPath "src/app/layout.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
import type { MetadataRoute } from "next";
import { listPublishedPosts } from "@/lib/repo";

export const dynamic = "force-dynamic";

function siteUrl(): string {
  return (process.env.APP_URL || "http://localhost:3000").replace(/\/$/, "");
}

export default function sitemap(): MetadataRoute.Sitemap {
  const base = siteUrl();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${base}/`, changeFrequency: "weekly", priority: 1 },
    { url: `${base}/about`, changeFrequency: "monthly", priority: 0.6 },
    { url: `${base}/foundation`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${base}/impact`, changeFrequency: "weekly", priority: 0.8 },
    { url: `${base}/get-involved`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/blog`, changeFrequency: "daily", priority: 0.8 },
    { url: `${base}/register`, changeFrequency: "monthly", priority: 0.5 },
    { url: `${base}/register/free`, changeFrequency: "monthly", priority: 0.5 },
  ];

  const postRoutes: MetadataRoute.Sitemap = listPublishedPosts().map((post) => ({
    url: `${base}/blog/${post.slug}`,
    lastModified: post.updatedAt,
    changeFrequency: "monthly",
    priority: 0.6,
  }));

  return [...staticRoutes, ...postRoutes];
}

'@ | Set-Content -LiteralPath "src/app/sitemap.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app" | Out-Null
@'
import Link from "next/link";
import { getSiteContent, listImpactStories } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PathRoute } from "@/components/path-route";
import { ArrowRight } from "@/components/arrow-right";

export const dynamic = "force-dynamic";

const CREDIBILITY_POINTS = [
  "One-on-one mentoring",
  "Scholarship-focused applications",
  "Student-centered support",
  "International study pathways",
];

const WHAT_STUDENTS_RECEIVE = [
  {
    title: "A tailored university shortlist",
    body: "Schools matched to your grades, goals, and budget — not a generic list.",
  },
  {
    title: "Personal statement & essay guidance",
    body: "One-on-one feedback to help your application sound like you, at your best.",
  },
  {
    title: "Scholarship & financial-aid search",
    body: "We help you find and apply for merit-based and need-based aid, especially in the US.",
  },
  {
    title: "Document review & tracking",
    body: "Your own portal to track every document and every stage — always up to date.",
  },
  {
    title: "Interview preparation",
    body: "Practice and coaching where an admissions or scholarship interview is required.",
  },
];

export default function HomePage() {
  const content = getSiteContent();
  const testimonial = listImpactStories().find((s) => s.featured === 1);

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        {/* Hero — full-bleed navy, IvyWise-style */}
        <section
          className="relative bg-navy text-paper overflow-hidden bg-cover bg-center"
          style={content.heroImageUrl ? { backgroundImage: `url(${content.heroImageUrl})` } : undefined}
        >
          {content.heroImageUrl && <div className="absolute inset-0 bg-navy/75" />}
          <div
            className="absolute inset-0 opacity-40"
            style={{
              background:
                "radial-gradient(ellipse 90% 60% at 50% -10%, rgba(15,110,140,0.55), transparent 60%)",
            }}
          />
          <div className="relative mx-auto max-w-5xl px-6 pt-24 pb-20 text-center">
            <p className="uppercase tracking-[0.25em] text-xs text-paper/70 font-medium">
              {content.orgName}
            </p>
            <h1 className="font-display text-4xl sm:text-6xl leading-[1.08] mt-5">
              Talent should decide who gets in.
              <br className="hidden sm:block" /> Not a bank balance.
            </h1>
            <p className="mt-6 text-lg text-paper/75 max-w-xl mx-auto">{content.tagline}</p>
            <div className="mt-9 flex flex-wrap justify-center gap-4">
              <Link
                href="/register"
                className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors"
              >
                Get application support
              </Link>
              <Link
                href="/about"
                className="rounded-full border border-paper/30 px-7 py-3 hover:border-paper/70 transition-colors"
              >
                Meet the team
              </Link>
            </div>
            <div className="mt-4">
              <PathRoute />
            </div>
          </div>
        </section>

        {/* Credibility strip — what we offer, not raw headcounts */}
        <section className="border-b border-line bg-paper-dim">
          <div className="mx-auto max-w-6xl px-6 py-10 grid grid-cols-2 sm:grid-cols-4 gap-6 text-center">
            {CREDIBILITY_POINTS.map((point) => (
              <div key={point} className="flex flex-col items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-gold-deep" />
                <p className="text-sm font-medium">{point}</p>
              </div>
            ))}
          </div>
          <div className="text-center pb-8">
            <Link href="/impact" className="text-sm text-teal hover:underline">
              See our impact & student stories
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* What students receive */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Our services</p>
          <h2 className="font-display text-3xl mb-10">What students receive</h2>
          <div className="grid sm:grid-cols-2 gap-x-10 gap-y-8">
            {WHAT_STUDENTS_RECEIVE.map((item) => (
              <div key={item.title} className="flex gap-4">
                <span className="w-6 h-6 rounded-full bg-teal/10 text-teal grid place-items-center shrink-0 mt-0.5 text-xs font-medium">
                  ✓
                </span>
                <div>
                  <h3 className="font-medium mb-1">{item.title}</h3>
                  <p className="text-sm text-ink/70 leading-relaxed">{item.body}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Mission */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="grid sm:grid-cols-2 gap-10">
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Mission</p>
              <h2 className="font-display text-2xl mb-3">Why we exist</h2>
              <p className="text-ink/80 leading-relaxed">{content.mission}</p>
            </div>
            <div>
              <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">Vision</p>
              <h2 className="font-display text-2xl mb-3">Where we're headed</h2>
              <p className="text-ink/80 leading-relaxed">{content.vision}</p>
            </div>
          </div>
        </section>

        {/* Testimonial — only shown once a real, permitted story is marked featured in admin */}
        {testimonial && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <div className="rounded-2xl border border-gold-deep/30 bg-gold/5 px-8 py-10 sm:px-12 text-center">
              <p className="font-display text-2xl sm:text-3xl leading-snug text-ink mb-6">
                &ldquo;{testimonial.story}&rdquo;
              </p>
              <p className="text-sm font-medium">{testimonial.studentName}</p>
              <p className="text-xs text-ink/50 uppercase tracking-wide mt-1">
                {testimonial.destinationCountry}
              </p>
            </div>
          </section>
        )}

        {/* Caretaking foundation — short summary, full story lives on its own page */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 sm:px-12 sm:py-14">
            <p className="uppercase tracking-[0.2em] text-xs text-paper/60 font-medium mb-3">
              Beyond admissions
            </p>
            <h2 className="font-display text-2xl mb-3">About the Foundation</h2>
            <p className="text-paper/80 max-w-2xl leading-relaxed mb-6">
              WorldPath Caretaking Foundation is the nonprofit organization behind WorldPath Group,
              supporting education, mentorship, healthcare outreach, and community development across
              Ghana.
            </p>
            <Link
              href="/foundation"
              className="text-sm text-paper underline hover:text-teal transition-colors"
            >
              Learn more about the Foundation
              <ArrowRight />
            </Link>
          </div>
        </section>

        {/* Blog teaser */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <div className="flex items-center justify-between mb-3">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">From the blog</p>
            <Link href="/blog" className="text-sm text-teal hover:underline">
              All posts
              <ArrowRight />
            </Link>
          </div>
          <h2 className="font-display text-2xl mb-3">Guides for applying abroad</h2>
          <p className="text-ink/70 max-w-2xl">
            Scholarship tips, application walkthroughs, and stories from students on their way abroad.
          </p>
        </section>

        {/* Free partnership note + CTA */}
        <section className="mx-auto max-w-6xl px-6 py-16">
          <div className="grid sm:grid-cols-2 gap-10 items-center">
            <div>
              <h2 className="font-display text-2xl mb-3">Free through Wesley Senior High School</h2>
              <p className="text-ink/80 leading-relaxed">
                Through our partnership with Wesley Senior High School, application assistance is
                provided free of charge to eligible students.
              </p>
            </div>
            <div className="sm:text-right">
              <Link href="/register/free" className="btn-primary inline-block">
                Apply for WorldPath guidance
              </Link>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/foundation" | Out-Null
@'
import type { Metadata } from "next";
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `WorldPath Caretaking Foundation | ${content.orgName}`,
    description:
      "The nonprofit organization behind WorldPath Group, supporting education, mentorship, healthcare outreach, and community development across Ghana.",
  };
}

export default function FoundationPage() {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-20">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">Beyond admissions</p>
          <h1 className="font-display text-4xl mt-4 mb-8">WorldPath Caretaking Foundation</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">
            {content.caretakingInfo ||
              "Beyond university placement, our parent foundation supports caretaking homes with food and daily necessities — because a student's wellbeing at home is part of their path to university too."}
          </p>

          <div className="mt-12 pt-8 border-t border-line">
            <Link href="/get-involved" className="btn-primary inline-block">
              See how you can help
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter
        orgName={content.orgName}
        contactEmail={content.contactEmail}
        contactPhone={content.contactPhone}
        address={content.address}
      />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/app/foundation/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/admin" | Out-Null
@'
import Link from "next/link";
import { listStudents, listStaff, listBoardMembers, listUsers } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import { ArrowRight } from "@/components/arrow-right";

export const dynamic = "force-dynamic";

export default function AdminDashboard() {
  const students = listStudents();
  const staff = listStaff();
  const board = listBoardMembers();
  const users = listUsers();

  const unassigned = students.filter((s) => !s.assignedStaffId).length;

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Dashboard</h1>
      <p className="text-ink/60 mb-8">A quick look at WorldPath Group right now.</p>

      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
        <Stat label="Students" value={students.length} href="/admin/students" />
        <Stat label="Unassigned students" value={unassigned} href="/admin/students" accent={unassigned > 0} />
        <Stat label="Staff members" value={staff.length} href="/admin/staff" />
        <Stat label="Board members" value={board.length} href="/admin/board" />
      </div>

      <div className="grid sm:grid-cols-2 gap-8">
        <div>
          <h2 className="font-display text-xl mb-4">Applications by stage</h2>
          <div className="space-y-2">
            {APPLICATION_STATUSES.map((status) => {
              const count = students.filter((s) => s.status === status.value).length;
              return (
                <div key={status.value} className="flex items-center justify-between border-b border-line py-2 text-sm">
                  <span>{status.label}</span>
                  <span className="font-medium">{count}</span>
                </div>
              );
            })}
          </div>
        </div>
        <div>
          <h2 className="font-display text-xl mb-4">Accounts</h2>
          <div className="space-y-2 text-sm">
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Admins</span>
              <span className="font-medium">{users.filter((u) => u.role === "admin").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Staff</span>
              <span className="font-medium">{users.filter((u) => u.role === "staff").length}</span>
            </div>
            <div className="flex items-center justify-between border-b border-line py-2">
              <span>Students</span>
              <span className="font-medium">{users.filter((u) => u.role === "student").length}</span>
            </div>
          </div>
          <Link href="/admin/users" className="inline-block mt-4 text-sm text-teal hover:underline">
            Manage accounts
            <ArrowRight />
          </Link>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value, href, accent }: { label: string; value: number; href: string; accent?: boolean }) {
  return (
    <Link
      href={href}
      className={`block border rounded-xl p-5 hover:border-ink transition-colors ${
        accent ? "border-gold-deep bg-gold/5" : "border-line"
      }`}
    >
      <p className="text-3xl font-display">{value}</p>
      <p className="text-sm text-ink/60 mt-1">{label}</p>
    </Link>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/register" | Out-Null
@'
"use client";

import { useActionState, useRef, startTransition } from "react";
import Link from "next/link";
import { registerAction, type FormState } from "@/app/actions/auth";
import { TARGET_LEVELS, TARGET_COUNTRIES, CURRENT_EDUCATION_LEVELS } from "@/types";
import { PhotoUploadField } from "@/components/photo-upload-field";
import { ArrowRight } from "@/components/arrow-right";

const initialState: FormState = {};

export default function RegisterPage() {
  const [state, formAction, pending] = useActionState(registerAction, initialState);
  const formRef = useRef<HTMLFormElement>(null);

  // React resets uncontrolled form fields the moment a <form action={...}>
  // submits — including on a failed submission. On a form this long,
  // that means a student who forgets one field (like the photo) would
  // see everything they typed disappear. Submitting manually like this,
  // instead of wiring `action` directly to the form, keeps their answers
  // on screen if something needs fixing.
  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    startTransition(() => {
      formAction(formData);
    });
  }

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
            Apply through our free application program
            <ArrowRight />
          </Link>
        </div>

        <form ref={formRef} onSubmit={handleSubmit} className="space-y-5">
          <div>
            <span className="block text-sm font-medium mb-1.5">Your photo</span>
            <PhotoUploadField />
          </div>

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

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
export function ArrowRight({ className = "inline-block w-3.5 h-3.5 ml-1 -mb-0.5" }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
      <path
        d="M3 8h10M9 4l4 4-4 4"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

'@ | Set-Content -LiteralPath "src/components/arrow-right.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
import Link from "next/link";

export function SiteFooter({
  orgName,
  contactEmail,
  contactPhone,
  address,
}: {
  orgName: string;
  contactEmail: string;
  contactPhone?: string;
  address: string;
}) {
  return (
    <footer className="border-t border-line mt-24">
      <div className="mx-auto max-w-6xl px-6 py-10 flex flex-col sm:flex-row justify-between gap-6 text-sm text-ink/70">
        <p>
          &copy; {new Date().getFullYear()} {orgName}. A project of{" "}
          <Link href="/foundation" className="hover:text-teal transition-colors underline">
            WorldPath Caretaking Foundation
          </Link>
          .
        </p>
        <div className="flex flex-col sm:items-end gap-0.5">
          {contactEmail && <span>{contactEmail}</span>}
          {contactPhone && <span>{contactPhone}</span>}
          {address && <span className="whitespace-pre-line sm:text-right">{address}</span>}
        </div>
      </div>
    </footer>
  );
}

'@ | Set-Content -LiteralPath "src/components/site-footer.tsx" -Encoding utf8

git add .
git commit -m "Consolidated fix: hero image upload + homepage credibility redesign"
git push

Write-Host 'Done. Files written and pushed.'