# WorldPath Group - How it works section, founder credibility spotlight,
# dedicated program pages (undergrad/masters/PhD/scholarships), contact
# page with working form, and an expanded footer linking everything
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
    "ALTER TABLE site_content ADD COLUMN founderName TEXT NOT NULL DEFAULT 'Cyril Asirifi Kwame'",
    "ALTER TABLE site_content ADD COLUMN founderTitle TEXT NOT NULL DEFAULT 'Founder & Executive Director'",
    "ALTER TABLE site_content ADD COLUMN founderBio TEXT NOT NULL DEFAULT 'Passionate about expanding access to international education and scholarship opportunities for students across Ghana.'",
    "ALTER TABLE site_content ADD COLUMN founderPhotoUrl TEXT",
    "ALTER TABLE site_content ADD COLUMN undergradInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN mastersInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN phdInfo TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE site_content ADD COLUMN scholarshipsInfo TEXT NOT NULL DEFAULT ''",
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
  founderName: string;
  founderTitle: string;
  founderBio: string;
  founderPhotoUrl: string | null;
  undergradInfo: string;
  mastersInfo: string;
  phdInfo: string;
  scholarshipsInfo: string;
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

export type LeadType = "volunteer" | "donate" | "apply_interest" | "contact";

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
      `UPDATE site_content SET orgName = ?, tagline = ?, mission = ?, vision = ?, contactEmail = ?, contactPhone = ?, address = ?, donateInfo = ?, logoUrl = ?, heroImageUrl = ?, founderName = ?, founderTitle = ?, founderBio = ?, founderPhotoUrl = ?, undergradInfo = ?, mastersInfo = ?, phdInfo = ?, scholarshipsInfo = ?, caretakingInfo = ?
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
      input.founderName,
      input.founderTitle,
      input.founderBio,
      input.founderPhotoUrl,
      input.undergradInfo,
      input.mastersInfo,
      input.phdInfo,
      input.scholarshipsInfo,
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
  founderName: z.string().optional().default(""),
  founderTitle: z.string().optional().default(""),
  founderBio: z.string().optional().default(""),
  founderPhotoUrl: z.string().optional().default(""),
  undergradInfo: z.string().optional().default(""),
  mastersInfo: z.string().optional().default(""),
  phdInfo: z.string().optional().default(""),
  scholarshipsInfo: z.string().optional().default(""),
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
    type: z.enum(["volunteer", "donate", "apply_interest", "contact"]),
    name: z.string().min(2, "Enter your name"),
    email: z.string().email("Enter a valid email address"),
    phone: z.string().optional().default(""),
    message: z.string().optional().default(""),
    areasOfInterest: z.array(z.string()).optional().default([]),
    availability: z.string().optional().default(""),
  })
  .refine((data) => !["donate", "contact"].includes(data.type) || data.message.trim().length > 0, {
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

  const existingFounderPhotoUrl = String(formData.get("existingFounderPhotoUrl") || "");
  const founderPhotoFile = formData.get("founderPhoto");

  let founderPhotoUrl = existingFounderPhotoUrl;
  if (founderPhotoFile instanceof File && founderPhotoFile.size > 0) {
    try {
      founderPhotoUrl = await saveUploadedImage(founderPhotoFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
    if (existingFounderPhotoUrl) await deleteUploadedImage(existingFounderPhotoUrl);
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
    founderName: String(formData.get("founderName") || ""),
    founderTitle: String(formData.get("founderTitle") || ""),
    founderBio: String(formData.get("founderBio") || ""),
    undergradInfo: String(formData.get("undergradInfo") || ""),
    mastersInfo: String(formData.get("mastersInfo") || ""),
    phdInfo: String(formData.get("phdInfo") || ""),
    scholarshipsInfo: String(formData.get("scholarshipsInfo") || ""),
    logoUrl,
    heroImageUrl,
    founderPhotoUrl,
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  updateSiteContent(parsed.data);
  revalidatePath("/");
  revalidatePath("/about");
  revalidatePath("/foundation");
  revalidatePath("/programs/undergraduate");
  revalidatePath("/programs/masters");
  revalidatePath("/programs/phd");
  revalidatePath("/scholarships");
  revalidatePath("/contact");
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
    founderName: string;
    founderTitle: string;
    founderBio: string;
    founderPhotoUrl: string | null;
    undergradInfo: string;
    mastersInfo: string;
    phdInfo: string;
    scholarshipsInfo: string;
    caretakingInfo: string;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(updateSiteContentAction, {});

  return (
    <form action={formAction} className="space-y-8 max-w-2xl">
      <Section title="Branding">
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
      </Section>

      <Section title="Organization">
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
      </Section>

      <Section title="Founder">
        <div>
          <span className="block text-sm font-medium mb-1.5">Founder photo</span>
          <PhotoUploadField
            existingUrl={content.founderPhotoUrl}
            name="founderPhoto"
            hiddenFieldName="existingFounderPhotoUrl"
          />
        </div>
        <div className="grid sm:grid-cols-2 gap-5">
          <Field label="Name">
            <input name="founderName" defaultValue={content.founderName} className="input" />
          </Field>
          <Field label="Title">
            <input name="founderTitle" defaultValue={content.founderTitle} className="input" />
          </Field>
        </div>
        <Field label="Short bio">
          <textarea name="founderBio" defaultValue={content.founderBio} rows={3} className="input" />
        </Field>
      </Section>

      <Section title="Program pages">
        <p className="text-xs text-ink/50 -mt-2">
          Each of these becomes its own page (e.g. worldpathgroup.org/programs/undergraduate). Leave a field
          empty and that page shows a simple default message instead.
        </p>
        <Field label="Undergraduate applications">
          <textarea name="undergradInfo" defaultValue={content.undergradInfo} rows={4} className="input" />
        </Field>
        <Field label="Master's applications">
          <textarea name="mastersInfo" defaultValue={content.mastersInfo} rows={4} className="input" />
        </Field>
        <Field label="PhD applications">
          <textarea name="phdInfo" defaultValue={content.phdInfo} rows={4} className="input" />
        </Field>
        <Field label="Scholarships">
          <textarea name="scholarshipsInfo" defaultValue={content.scholarshipsInfo} rows={4} className="input" />
        </Field>
      </Section>

      <Section title="WorldPath Caretaking Foundation">
        <Field label="Description (projects, partnerships — shown on the homepage and the Foundation page)">
          <textarea
            name="caretakingInfo"
            defaultValue={content.caretakingInfo}
            rows={5}
            className="input"
            placeholder="Describe your caretaking projects and partnerships, e.g. work with God Matters Fellowship..."
          />
        </Field>
      </Section>

      <Section title="Contact">
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
      </Section>

      <Section title="Donate">
        <Field label="Donate details (bank account / mobile money — shown on the Get Involved page)">
          <textarea name="donateInfo" defaultValue={content.donateInfo} rows={4} className="input" />
        </Field>
      </Section>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : "Save changes"}
      </button>
    </form>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="pt-6 first:pt-0 border-t border-line first:border-0">
      <h2 className="font-display text-lg mb-4">{title}</h2>
      <div className="space-y-5">{children}</div>
    </div>
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

New-Item -ItemType Directory -Force -Path "src/app/admin/leads" | Out-Null
@'
import { listLeads } from "@/lib/repo";
import { HandledToggle } from "./handled-toggle";

export const dynamic = "force-dynamic";

const TYPE_LABEL: Record<string, string> = {
  volunteer: "Volunteer",
  donate: "Donate inquiry",
  apply_interest: "Apply interest",
  contact: "Contact form",
};

export default function AdminLeadsPage() {
  const leads = listLeads();
  const open = leads.filter((l) => !l.handled);

  return (
    <div>
      <h1 className="font-display text-3xl mb-2">Leads</h1>
      <p className="text-ink/60 mb-8">
        Volunteer and donation inquiries submitted from the Get Involved page. {open.length} awaiting a reply.
      </p>

      <div className="divide-y divide-line border border-line rounded-xl">
        {leads.length === 0 && <p className="p-6 text-sm text-ink/50 italic">No inquiries yet.</p>}
        {leads.map((l) => {
          const areas = l.areasOfInterest ? (JSON.parse(l.areasOfInterest) as string[]) : [];
          return (
            <div key={l.id} className={`p-4 ${l.handled ? "opacity-60" : ""}`}>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium">
                    {l.name} <span className="text-xs uppercase text-gold-deep ml-2">{TYPE_LABEL[l.type] ?? l.type}</span>
                  </p>
                  <p className="text-sm text-ink/60">
                    {l.email}
                    {l.phone ? ` · ${l.phone}` : ""}
                  </p>
                  {areas.length > 0 && (
                    <p className="text-sm text-teal mt-2">{areas.join(" · ")}</p>
                  )}
                  {l.availability && <p className="text-sm text-ink/60 mt-1">Availability: {l.availability}</p>}
                  {l.message && <p className="text-sm text-ink/80 mt-2 max-w-xl">{l.message}</p>}
                  <p className="text-xs text-ink/40 mt-2">{new Date(l.createdAt).toLocaleString()}</p>
                </div>
                <HandledToggle id={l.id} handled={l.handled === 1} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/app/admin/leads/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
import Link from "next/link";
import { getSiteContent } from "@/lib/repo";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";

export function ProgramPageLayout({
  eyebrow,
  title,
  body,
  fallback,
  applyHref = "/register",
}: {
  eyebrow: string;
  title: string;
  body: string;
  fallback: string;
  applyHref?: string;
}) {
  const content = getSiteContent();

  return (
    <>
      <SiteHeader orgName={content.orgName} logoUrl={content.logoUrl} />
      <main className="flex-1">
        <section className="mx-auto max-w-3xl px-6 pt-16 pb-8">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium">{eyebrow}</p>
          <h1 className="font-display text-4xl mt-4 mb-6">{title}</h1>
          <p className="text-lg text-ink/80 leading-relaxed whitespace-pre-line">{body || fallback}</p>
        </section>

        <section className="mx-auto max-w-3xl px-6 pb-20">
          <div className="rounded-2xl bg-navy text-paper px-8 py-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
            <div>
              <h2 className="font-display text-xl mb-2">Ready to get started?</h2>
              <p className="text-paper/75">We'll match you with a counselor to guide your application.</p>
            </div>
            <Link href={applyHref} className="rounded-full bg-teal text-paper px-7 py-3 hover:bg-gold-deep transition-colors shrink-0 text-center">
              Get application support
            </Link>
          </div>
        </section>
      </main>
      <SiteFooter orgName={content.orgName} contactEmail={content.contactEmail} contactPhone={content.contactPhone} address={content.address} />
    </>
  );
}

'@ | Set-Content -LiteralPath "src/components/program-page-layout.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/undergraduate" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Undergraduate Applications | ${content.orgName}`,
    description: "Application support for undergraduate study abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function UndergraduatePage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Undergraduate"
      title="Undergraduate applications"
      body={content.undergradInfo}
      fallback="We help Ghanaian students build a competitive undergraduate application — from choosing the right universities to writing standout essays and finding scholarships to make it affordable."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/undergraduate/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/masters" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `Master's Applications | ${content.orgName}`,
    description: "Application support for master's degrees abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function MastersPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="Master's"
      title="Master's applications"
      body={content.mastersInfo}
      fallback="We support Ghanaian graduates applying for master's programs abroad — from selecting programs aligned with your career goals to strengthening your statement of purpose and finding funding."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/masters/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/programs/phd" | Out-Null
@'
import type { Metadata } from "next";
import { getSiteContent } from "@/lib/repo";
import { ProgramPageLayout } from "@/components/program-page-layout";

export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const content = getSiteContent();
  return {
    title: `PhD Applications | ${content.orgName}`,
    description: "Application support for PhD programs abroad, from Ghana to the USA, Canada, UK, Germany, and Asia.",
  };
}

export default function PhdPage() {
  const content = getSiteContent();
  return (
    <ProgramPageLayout
      eyebrow="PhD"
      title="PhD applications"
      body={content.phdInfo}
      fallback="We support Ghanaian students pursuing doctoral study abroad — from identifying the right advisors and programs to preparing research proposals and securing funding."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/programs/phd/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/scholarships" | Out-Null
@'
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
      fallback="We help you find and apply for merit-based and need-based scholarships and financial aid — especially at US universities, where most funding decisions are made as part of the admissions process itself."
    />
  );
}

'@ | Set-Content -LiteralPath "src/app/scholarships/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/contact" | Out-Null
@'
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

'@ | Set-Content -LiteralPath "src/app/contact/page.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/contact" | Out-Null
@'
"use client";

import { useActionState } from "react";
import { submitLeadAction, type FormState } from "@/app/actions/leads";

export function ContactForm() {
  const [state, formAction, pending] = useActionState<FormState, FormData>(submitLeadAction, {});

  if (state.success) {
    return <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>;
  }

  return (
    <form action={formAction} className="space-y-4">
      <input type="hidden" name="type" value="contact" />
      <input name="name" required placeholder="Your name" className="input" />
      <input name="email" type="email" required placeholder="Email address" className="input" />
      <textarea name="message" required rows={4} placeholder="How can we help?" className="input" />

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Sending..." : "Send message"}
      </button>
    </form>
  );
}

'@ | Set-Content -LiteralPath "src/app/contact/contact-form.tsx" -Encoding utf8

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

const HOW_IT_WORKS = [
  { title: "Apply online", body: "Create your account and tell us about your goals." },
  { title: "Meet an advisor", body: "We match you with a counselor to plan your path." },
  { title: "Prepare documents", body: "Essays, transcripts, and recommendations — reviewed together." },
  { title: "Submit applications", body: "We help you apply to universities and scholarships on time." },
  { title: "Track results", body: "Follow every stage from your own student portal." },
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

        {/* How it works */}
        <section className="mx-auto max-w-6xl px-6 py-16 border-b border-line">
          <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-3">The process</p>
          <h2 className="font-display text-3xl mb-10">How it works</h2>
          <div className="grid sm:grid-cols-5 gap-6">
            {HOW_IT_WORKS.map((step, i) => (
              <div key={step.title}>
                <span className="font-display text-2xl text-gold-deep">{i + 1}</span>
                <h3 className="font-medium mt-2 mb-1">{step.title}</h3>
                <p className="text-sm text-ink/70 leading-relaxed">{step.body}</p>
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

        {/* Founder */}
        {content.founderName && (
          <section className="mx-auto max-w-4xl px-6 py-16 border-b border-line">
            <p className="uppercase tracking-[0.2em] text-xs text-gold-deep font-medium mb-6 text-center sm:text-left">
              Leadership
            </p>
            <div className="flex flex-col sm:flex-row items-center sm:items-start gap-8 text-center sm:text-left">
              <div className="w-32 h-32 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
                {content.founderPhotoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={content.founderPhotoUrl} alt={content.founderName} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full grid place-items-center text-3xl text-ink/30 font-display">
                    {content.founderName.charAt(0)}
                  </div>
                )}
              </div>
              <div>
                <h2 className="font-display text-2xl mb-1">{content.founderName}</h2>
                <p className="text-teal text-sm font-medium mb-4">{content.founderTitle}</p>
                <p className="text-ink/80 leading-relaxed max-w-xl">{content.founderBio}</p>
              </div>
            </div>
          </section>
        )}

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
    { url: `${base}/programs/undergraduate`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/programs/masters`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/programs/phd`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/scholarships`, changeFrequency: "monthly", priority: 0.7 },
    { url: `${base}/contact`, changeFrequency: "monthly", priority: 0.5 },
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
      <div className="mx-auto max-w-6xl px-6 py-14 grid sm:grid-cols-4 gap-10 text-sm">
        <div className="sm:col-span-1">
          <p className="font-display text-base mb-2">{orgName}</p>
          <p className="text-ink/60 leading-relaxed">
            A project of{" "}
            <Link href="/foundation" className="hover:text-teal transition-colors underline">
              WorldPath Caretaking Foundation
            </Link>
            .
          </p>
        </div>

        <FooterColumn
          title="Programs"
          links={[
            { href: "/programs/undergraduate", label: "Undergraduate" },
            { href: "/programs/masters", label: "Master's" },
            { href: "/programs/phd", label: "PhD" },
            { href: "/scholarships", label: "Scholarships" },
          ]}
        />

        <FooterColumn
          title="Organization"
          links={[
            { href: "/about", label: "About WorldPath" },
            { href: "/impact", label: "Impact" },
            { href: "/blog", label: "Blog" },
            { href: "/get-involved", label: "Get Involved" },
          ]}
        />

        <div>
          <p className="font-medium mb-3">Contact</p>
          <div className="space-y-1 text-ink/60">
            {contactEmail && <p>{contactEmail}</p>}
            {contactPhone && <p>{contactPhone}</p>}
            {address && <p className="whitespace-pre-line">{address}</p>}
          </div>
          <Link href="/contact" className="inline-block mt-2 text-teal hover:underline">
            Contact page
          </Link>
        </div>
      </div>
      <div className="border-t border-line">
        <p className="mx-auto max-w-6xl px-6 py-5 text-xs text-ink/50">
          &copy; {new Date().getFullYear()} {orgName}. All rights reserved.
        </p>
      </div>
    </footer>
  );
}

function FooterColumn({ title, links }: { title: string; links: { href: string; label: string }[] }) {
  return (
    <div>
      <p className="font-medium mb-3">{title}</p>
      <ul className="space-y-1.5">
        {links.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="text-ink/60 hover:text-teal transition-colors">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/components/site-footer.tsx" -Encoding utf8

git add .
git commit -m "Add How it works, founder section, program pages, contact page"
git push

Write-Host 'Done. Files written and pushed.'