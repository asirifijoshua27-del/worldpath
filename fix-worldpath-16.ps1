# WorldPath Group - notifications, auto-logout, welcome email, and the
# standard-application form-request flow
# Run this from inside your worldpath project folder (where package.json lives)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
﻿import { DatabaseSync } from "node:sqlite";
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

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      link TEXT,
      read INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
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
      // Column already exists â€” fine.
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

/**
 * Temporarily disables foreign key enforcement, runs fn, then re-enables it.
 * Used only for account deletion: a deleted staff/admin's authored messages
 * are kept (for the student's record) rather than deleted, which would
 * otherwise violate the foreign key on student_notes.authorId.
 */
export function withForeignKeysOff<T>(fn: () => T): T {
  const raw = getDb();
  raw.exec("PRAGMA foreign_keys = OFF;");
  try {
    return fn();
  } finally {
    raw.exec("PRAGMA foreign_keys = ON;");
  }
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
﻿export type Role = "admin" | "staff" | "student";

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

export type NotificationType =
  | "message"
  | "document_uploaded"
  | "status_changed"
  | "student_assigned"
  | "new_student"
  | "new_lead"
  | "form_requested";

export interface NotificationRecord {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  link: string | null;
  read: number;
  createdAt: string;
}

'@ | Set-Content -LiteralPath "src/types/index.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
﻿import { db, newId, nowIso, nextStudentCode, withForeignKeysOff } from "@/lib/db";
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
  NotificationRecord,
  NotificationType,
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

export function countAdmins(): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM users WHERE role = 'admin'").get() as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

/**
 * Deletes a user account and whatever it owns: for staff, their public
 * profile (and unassigns any students); for students, their application
 * record. Messages the account authored are kept for the record â€” see
 * listNotesForStudent â€” rather than deleted.
 */
export function deleteUserAccount(userId: string): { staffPhotoUrl: string | null; studentPhotoUrl: string | null; documentUrls: string[] } {
  const database = db();
  let staffPhotoUrl: string | null = null;
  let studentPhotoUrl: string | null = null;
  let documentUrls: string[] = [];

  withForeignKeysOff(() => {
    const staff = database.prepare("SELECT * FROM staff_profiles WHERE userId = ?").get(userId) as
      | StaffProfileRecord
      | undefined;
    if (staff) {
      staffPhotoUrl = staff.photoUrl;
      database.prepare("UPDATE students SET assignedStaffId = NULL WHERE assignedStaffId = ?").run(staff.id);
      database.prepare("DELETE FROM staff_profiles WHERE id = ?").run(staff.id);
    }

    const student = database.prepare("SELECT * FROM students WHERE userId = ?").get(userId) as
      | StudentRecord
      | undefined;
    if (student) {
      studentPhotoUrl = student.photoUrl;
      documentUrls = (JSON.parse(student.documents) as { fileUrl?: string | null }[])
        .map((d) => d.fileUrl)
        .filter((u): u is string => Boolean(u));
      database.prepare("DELETE FROM students WHERE id = ?").run(student.id);
    }

    database.prepare("DELETE FROM email_verifications WHERE userId = ?").run(userId);
    database.prepare("DELETE FROM users WHERE id = ?").run(userId);
  });

  return { staffPhotoUrl, studentPhotoUrl, documentUrls };
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
      `SELECT n.*, COALESCE(u.name, 'Former team member') as authorName, COALESCE(u.role, 'staff') as authorRole
       FROM student_notes n
       LEFT JOIN users u ON u.id = n.authorId
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


// ---------- Notifications ----------

export function createNotification(input: {
  userId: string;
  type: NotificationType;
  title: string;
  body?: string;
  link?: string;
}) {
  db()
    .prepare(
      `INSERT INTO notifications (id, userId, type, title, body, link, read, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, 0, ?)`
    )
    .run(newId(), input.userId, input.type, input.title, input.body ?? "", input.link ?? null, nowIso());
}

/** Notify every admin at once - used for events any admin should see (new student, new lead). */
export function notifyAllAdmins(input: { type: NotificationType; title: string; body?: string; link?: string }) {
  const admins = db().prepare("SELECT id FROM users WHERE role = 'admin'").all() as unknown as { id: string }[];
  for (const admin of admins) {
    createNotification({ ...input, userId: admin.id });
  }
}

export function listNotifications(userId: string, limit = 20): NotificationRecord[] {
  return db()
    .prepare("SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC LIMIT ?")
    .all(userId, limit) as unknown as NotificationRecord[];
}

export function countUnreadNotifications(userId: string): number {
  const row = db().prepare("SELECT COUNT(*) as count FROM notifications WHERE userId = ? AND read = 0").get(userId) as
    | { count: number }
    | undefined;
  return row?.count ?? 0;
}

export function markNotificationRead(id: string, userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE id = ? AND userId = ?").run(id, userId);
}

export function markAllNotificationsRead(userId: string) {
  db().prepare("UPDATE notifications SET read = 1 WHERE userId = ? AND read = 0").run(userId);
}

'@ | Set-Content -LiteralPath "src/lib/repo.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/lib" | Out-Null
@'
﻿import { Resend } from "resend";

// Sends the email-verification link via Resend when RESEND_API_KEY is set.
// Without it (e.g. local development), the link is logged to the server
// console instead, so registration is always testable even with zero
// email setup.

function logToConsole(to: string, name: string, verifyUrl: string) {
  console.log("\n================ WorldPath Group: verification email ================");
  console.log(`To: ${to}`);
  console.log(`Hi ${name}, verify your email and set your password here:`);
  console.log(verifyUrl);
  console.log("=======================================================================\n");
}

function emailHtml(name: string, verifyUrl: string): string {
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    <h1 style="font-size:22px;margin:0 0 16px;">Verify your email</h1>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">Hi ${name},</p>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">
      Thanks for registering with WorldPath Group. Click the button below to verify your
      email address and set your password.
    </p>
    <p style="margin:28px 0;">
      <a href="${verifyUrl}"
         style="background:#0f6e8c;color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:999px;font-size:15px;display:inline-block;">
        Verify email &amp; set password
      </a>
    </p>
    <p style="font-size:13px;line-height:1.6;color:#0a2e3d99;">
      Or copy and paste this link into your browser:<br />
      <span style="word-break:break-all;">${verifyUrl}</span>
    </p>
    <p style="font-size:13px;color:#0a2e3d66;margin-top:32px;">
      If you didn't create an account with WorldPath Group, you can safely ignore this email.
    </p>
  </div>`;
}

function emailText(name: string, verifyUrl: string): string {
  return `Hi ${name},\n\nThanks for registering with WorldPath Group. Verify your email and set your password here:\n${verifyUrl}\n\nIf you didn't create an account with WorldPath Group, you can safely ignore this email.`;
}

export async function sendVerificationEmail(to: string, name: string, verifyUrl: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";

  if (!apiKey) {
    logToConsole(to, name, verifyUrl);
    return;
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: "Verify your WorldPath Group account",
      html: emailHtml(name, verifyUrl),
      text: emailText(name, verifyUrl),
    });
    if (error) {
      console.error("Resend failed to send verification email:", error);
      logToConsole(to, name, verifyUrl); // don't leave the student stuck
    }
  } catch (err) {
    console.error("Error sending verification email via Resend:", err);
    logToConsole(to, name, verifyUrl);
  }
}

export class EmailSendError extends Error {}

function adminEmailHtml(body: string): string {
  const paragraphs = body
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => `<p style="font-size:15px;line-height:1.6;color:#0a2e3d;margin:0 0 14px;">${line}</p>`)
    .join("");
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    ${paragraphs}
  </div>`;
}

/**
 * General-purpose email sender used by the admin portal to message a
 * student directly. Throws EmailSendError if RESEND_API_KEY isn't
 * configured or the send fails, so the caller can show the admin a real
 * error rather than silently pretending it worked.
 */
export async function sendAdminEmail(
  to: string,
  subject: string,
  body: string,
  attachment?: { filename: string; content: Buffer } | null
) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";

  if (!apiKey) {
    throw new EmailSendError(
      "Email sending isn't configured yet (no RESEND_API_KEY set). This message wasn't sent."
    );
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject,
      html: adminEmailHtml(body),
      text: body,
      attachments: attachment ? [{ filename: attachment.filename, content: attachment.content }] : undefined,
    });
    if (error) {
      throw new EmailSendError(error.message || "Resend rejected this email.");
    }
  } catch (err) {
    if (err instanceof EmailSendError) throw err;
    throw new EmailSendError("Could not send email. Please try again.");
  }
}


function welcomeEmailHtml(name: string, portalUrl: string): string {
  return `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;color:#0a2e3d;">
    <p style="text-transform:uppercase;letter-spacing:0.15em;font-size:11px;color:#0b5c73;font-weight:600;margin:0 0 16px;">
      WorldPath Group
    </p>
    <h1 style="font-size:22px;margin:0 0 16px;">Welcome, ${name}!</h1>
    <p style="font-size:15px;line-height:1.6;color:#0a2e3d;">
      Your WorldPath Group account is ready. From your student portal you can track your
      application status, upload documents, and message your counselor directly.
    </p>
    <p style="margin:28px 0;">
      <a href="${portalUrl}"
         style="background:#0f6e8c;color:#ffffff;text-decoration:none;padding:12px 28px;border-radius:999px;font-size:15px;display:inline-block;">
        Go to my portal
      </a>
    </p>
    <p style="font-size:14px;line-height:1.6;color:#0a2e3dcc;">
      A quick tip: check your portal regularly. That's where you'll see updates on your
      application, requests from your counselor, and any documents you still need to submit.
    </p>
    <p style="font-size:13px;color:#0a2e3d66;margin-top:32px;">
      Questions? Just reply to this email or reach us at hello@worldpathgroup.org.
    </p>
  </div>`;
}

function welcomeEmailText(name: string, portalUrl: string): string {
  return `Welcome, ${name}!\n\nYour WorldPath Group account is ready. From your student portal you can track your application status, upload documents, and message your counselor directly.\n\nGo to your portal: ${portalUrl}\n\nTip: check your portal regularly for updates and requests from your counselor.\n\nQuestions? Reach us at hello@worldpathgroup.org.`;
}

/**
 * Sends the welcome email once a student finishes registration (verifies
 * their email and sets a password). Best-effort: failures are logged but
 * never thrown, so a Resend hiccup can't block the student from finishing
 * account setup.
 */
export async function sendWelcomeEmail(to: string, name: string) {
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || "WorldPath Group <onboarding@resend.dev>";
  const appUrl = process.env.APP_URL || "http://localhost:3000";
  const portalUrl = `${appUrl}/student`;

  if (!apiKey) {
    console.log(`(Resend not configured) Would send welcome email to ${to}`);
    return;
  }

  const resend = new Resend(apiKey);
  try {
    const { error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: "Welcome to WorldPath Group",
      html: welcomeEmailHtml(name, portalUrl),
      text: welcomeEmailText(name, portalUrl),
    });
    if (error) {
      console.error("Resend failed to send welcome email:", error);
    }
  } catch (err) {
    console.error("Error sending welcome email via Resend:", err);
  }
}

'@ | Set-Content -LiteralPath "src/lib/email.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { listNotifications, countUnreadNotifications, markNotificationRead, markAllNotificationsRead } from "@/lib/repo";

export async function getNotificationsAction() {
  const session = await getSession();
  if (!session) return { notifications: [], unreadCount: 0 };
  return {
    notifications: listNotifications(session.userId),
    unreadCount: countUnreadNotifications(session.userId),
  };
}

export async function markNotificationReadAction(id: string) {
  const session = await getSession();
  if (!session) return;
  markNotificationRead(id, session.userId);
  revalidatePath(`/${session.role}`);
}

export async function markAllNotificationsReadAction() {
  const session = await getSession();
  if (!session) return;
  markAllNotificationsRead(session.userId);
  revalidatePath(`/${session.role}`);
}

'@ | Set-Content -LiteralPath "src/app/actions/notifications.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
﻿"use server";

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
  countAdmins,
  deleteUserAccount,
  createNotification,
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

  if (staffId) {
    const staff = getStaffById(staffId);
    const student = getStudentById(studentId);
    const studentUser = student ? getUserById(student.userId) : undefined;
    if (staff?.userId && studentUser) {
      createNotification({
        userId: staff.userId,
        type: "student_assigned",
        title: "New student assigned to you",
        body: studentUser.name,
        link: `/staff/students/${studentId}`,
      });
    }
  }

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

const MAX_ATTACHMENT_BYTES = 8 * 1024 * 1024; // 8MB

async function readEmailAttachment(formData: FormData): Promise<{ filename: string; content: Buffer } | { error: string } | null> {
  const file = formData.get("attachment");
  if (!(file instanceof File) || file.size === 0) return null;
  if (file.size > MAX_ATTACHMENT_BYTES) {
    return { error: "Attachment must be smaller than 8MB." };
  }
  const content = Buffer.from(await file.arrayBuffer());
  return { filename: file.name, content };
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

  const attachment = await readEmailAttachment(formData);
  if (attachment && "error" in attachment) {
    return { error: attachment.error };
  }

  try {
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment);
  } catch (e) {
    if (e instanceof EmailSendError) return { error: e.message };
    throw e;
  }

  return { success: `Email sent to ${user.email}.` };
}

export async function emailStaffAction(staffId: string, _prev: FormState, formData: FormData): Promise<FormState> {
  await requireAdmin();

  const staff = getStaffById(staffId);
  if (!staff) {
    return { error: "Staff member not found." };
  }
  const user = staff.userId ? getUserById(staff.userId) : undefined;
  if (!user) {
    return { error: "This staff member doesn't have a linked login account yet, so there's no email to send to." };
  }

  const parsed = adminEmailSchema.safeParse({
    subject: String(formData.get("subject") || ""),
    body: String(formData.get("body") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachment = await readEmailAttachment(formData);
  if (attachment && "error" in attachment) {
    return { error: attachment.error };
  }

  try {
    await sendAdminEmail(user.email, parsed.data.subject, parsed.data.body, attachment);
  } catch (e) {
    if (e instanceof EmailSendError) return { error: e.message };
    throw e;
  }

  return { success: `Email sent to ${user.email}.` };
}

export async function deleteUserAction(userId: string): Promise<void> {
  const session = await requireAdmin();

  if (userId === session.userId) {
    throw new Error("You can't delete your own account while logged in as it.");
  }

  const target = getUserById(userId);
  if (!target) {
    throw new Error("Account not found.");
  }
  if (target.role === "admin" && countAdmins() <= 1) {
    throw new Error("You can't delete the last remaining admin account.");
  }

  const { staffPhotoUrl, studentPhotoUrl, documentUrls } = deleteUserAccount(userId);

  // Clean up any files this account owned, now that the DB rows are gone.
  await deleteUploadedImage(staffPhotoUrl);
  await deleteUploadedImage(studentPhotoUrl);
  for (const url of documentUrls) {
    await deleteUploadedImage(url);
  }

  revalidatePath("/admin/users");
  revalidatePath("/admin/staff");
  revalidatePath("/admin/students");
  revalidatePath("/about");
}


'@ | Set-Content -LiteralPath "src/app/actions/admin.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
﻿"use server";

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
  notifyAllAdmins,
} from "@/lib/repo";
import { sendVerificationEmail, sendWelcomeEmail } from "@/lib/email";
import { createSessionToken, setSessionCookie, clearSessionCookie } from "@/lib/auth";
import { saveUploadedImage, UploadError } from "@/lib/uploads";

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

  const photoFile = formData.get("photo");
  if (!(photoFile instanceof File) || photoFile.size === 0) {
    return { error: "Please attach a photo of yourself." };
  }
  let photoUrl: string;
  try {
    photoUrl = await saveUploadedImage(photoFile);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
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
    photoUrl,
  });

  notifyAllAdmins({
    type: "new_student",
    title: "New student registered",
    body: `${user.name} registered for a standard application.`,
    link: "/admin/students",
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

  const photoFile = formData.get("photo");
  if (!(photoFile instanceof File) || photoFile.size === 0) {
    return { error: "Please attach a photo of yourself." };
  }
  let photoUrl: string;
  try {
    photoUrl = await saveUploadedImage(photoFile);
  } catch (e) {
    if (e instanceof UploadError) return { error: e.message };
    throw e;
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
    photoUrl,
  });

  notifyAllAdmins({
    type: "new_student",
    title: "New free application registered",
    body: `${user.name} registered through the Wesley SHS free program.`,
    link: "/admin/students",
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

  // Registration is now complete - send the welcome email. Best-effort:
  // sendWelcomeEmail never throws, so a Resend hiccup can't block signup.
  await sendWelcomeEmail(user.email, user.name);

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
﻿"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { createLead, markLeadHandled, notifyAllAdmins } from "@/lib/repo";
import { leadSchema } from "@/lib/validators";
import type { FormState } from "@/app/actions/auth";
export type { FormState } from "@/app/actions/auth";

export async function submitLeadAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const parsed = leadSchema.safeParse({
    type: String(formData.get("type") || "volunteer"),
    name: String(formData.get("name") || ""),
    email: String(formData.get("email") || ""),
    phone: String(formData.get("phone") || ""),
    message: String(formData.get("message") || ""),
    areasOfInterest: formData.getAll("areasOfInterest").map(String),
    availability: String(formData.get("availability") || ""),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }
  createLead(parsed.data);

  const typeLabel = parsed.data.type === "donate" ? "Donate inquiry" : parsed.data.type === "contact" ? "Contact form" : "Volunteer";
  notifyAllAdmins({
    type: "new_lead",
    title: `New ${typeLabel.toLowerCase()} submission`,
    body: `${parsed.data.name} (${parsed.data.email})`,
    link: "/admin/leads",
  });

 return { success: "Thanks - we'll be in touch soon." };
}

export async function markLeadHandledAction(formData: FormData) {
  const session = await getSession();
  if (!session || session.role !== "admin") {
    throw new Error("Not authorized");
  }
  const id = String(formData.get("id") || "");
  const handled = formData.get("handled") === "true";
  markLeadHandled(id, handled);
  revalidatePath("/admin/leads");
}


'@ | Set-Content -LiteralPath "src/app/actions/leads.ts" -Encoding utf8

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
  createNotification,
} from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError } from "@/lib/uploads";
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
  const { student } = await requireOwningStaff(studentId);
  const status = String(formData.get("status") || "");
  updateStudentStatus(studentId, status);

  const statusLabel = APPLICATION_STATUSES.find((s) => s.value === status)?.label ?? status;
  createNotification({
    userId: student.userId,
    type: "status_changed",
    title: "Your application status changed",
    body: `Your status is now "${statusLabel}".`,
    link: "/student",
  });

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
  const { session, student } = await requireOwningStaff(studentId);
  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachmentFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (attachmentFile instanceof File && attachmentFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedDocument(attachmentFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a note or attach a file." };
  }

  addNote(studentId, session.userId, parsed.data.text.trim(), attachmentUrl);

  createNotification({
    userId: student.userId,
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
    link: "/student",
  });

  revalidatePath(`/staff/students/${studentId}`);
  return { success: "Note added." };
}

'@ | Set-Content -LiteralPath "src/app/actions/staff.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/actions" | Out-Null
@'
"use server";

import { revalidatePath } from "next/cache";
import { getSession } from "@/lib/auth";
import { getStudentByUserId, updateStudentDocuments, addNote, createNotification, getStaffById } from "@/lib/repo";
import { noteSchema } from "@/lib/validators";
import { saveUploadedDocument, UploadError, deleteUploadedImage } from "@/lib/uploads";
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

function notifyAssignedStaff(
  assignedStaffId: string | null,
  studentId: string,
  input: { type: "message" | "document_uploaded" | "form_requested"; title: string; body: string }
) {
  if (!assignedStaffId) return;
  const staff = getStaffById(assignedStaffId);
  if (!staff?.userId) return;
  createNotification({
    userId: staff.userId,
    type: input.type,
    title: input.title,
    body: input.body,
    link: `/staff/students/${studentId}`,
  });
}

export async function studentUploadDocumentAction(formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();
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

  notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "document_uploaded",
    title: `${session.name} uploaded a document`,
    body: docs[index].name,
  });

  revalidatePath("/student");
  return { success: "Document uploaded." };
}

export async function studentAddNoteAction(_prev: FormState, formData: FormData): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  const parsed = noteSchema.safeParse({ text: String(formData.get("text") || "") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message || "Please check the form." };
  }

  const attachmentFile = formData.get("image");
  let attachmentUrl: string | null = null;
  if (attachmentFile instanceof File && attachmentFile.size > 0) {
    try {
      attachmentUrl = await saveUploadedDocument(attachmentFile);
    } catch (e) {
      if (e instanceof UploadError) return { error: e.message };
      throw e;
    }
  }

  if (!parsed.data.text.trim() && !attachmentUrl) {
    return { error: "Add a message or attach a file." };
  }

  addNote(student.id, session.userId, parsed.data.text.trim(), attachmentUrl);

  notifyAssignedStaff(student.assignedStaffId, student.id, {
    type: "message",
    title: `New message from ${session.name}`,
    body: parsed.data.text.trim().slice(0, 80) || "Sent an attachment.",
  });

  revalidatePath("/student");
  return { success: "Message sent." };
}

/**
 * Standard (non-free) applicants request their application form from their
 * assigned counselor, rather than getting one automatically. This notifies
 * the counselor and drops a message in the shared thread so there's a
 * record of the request; the counselor replies with the form as a message
 * attachment.
 */
export async function requestApplicationFormAction(): Promise<FormState> {
  const { session, student } = await requireOwnStudentRecord();

  if (student.applicationType !== "standard") {
    return { error: "This is only needed for standard applications." };
  }
  if (!student.assignedStaffId) {
    return { error: "You don't have a counselor assigned yet. Please check back soon." };
  }

  const staff = getStaffById(student.assignedStaffId);
  if (!staff?.userId) {
    return { error: "Your counselor doesn't have an active account yet. Please check back soon." };
  }

  addNote(student.id, session.userId, "Requested the application form.");

  createNotification({
    userId: staff.userId,
    type: "form_requested",
    title: `${session.name} requested the application form`,
    body: "Reply in their message thread with the form attached.",
    link: `/staff/students/${student.id}`,
  });

  revalidatePath("/student");
  return { success: "Request sent to your counselor." };
}

'@ | Set-Content -LiteralPath "src/app/actions/student.ts" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import Link from "next/link";
import {
  getNotificationsAction,
  markNotificationReadAction,
  markAllNotificationsReadAction,
} from "@/app/actions/notifications";
import type { NotificationRecord } from "@/types";

const POLL_INTERVAL_MS = 20000;

export function NotificationBell() {
  const [notifications, setNotifications] = useState<NotificationRecord[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const refresh = useCallback(async () => {
    const result = await getNotificationsAction();
    setNotifications(result.notifications);
    setUnreadCount(result.unreadCount);
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  async function handleOpen(id: string) {
    await markNotificationReadAction(id);
    refresh();
  }

  async function handleMarkAllRead() {
    await markAllNotificationsReadAction();
    refresh();
  }

  return (
    <div className="relative" ref={containerRef}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="relative w-9 h-9 rounded-full grid place-items-center hover:bg-paper-dim transition-colors"
        aria-label="Notifications"
      >
        <svg viewBox="0 0 24 24" fill="none" className="w-5 h-5 text-ink/70" aria-hidden="true">
          <path
            d="M12 3a5 5 0 00-5 5v3.2c0 .53-.2 1.04-.56 1.42L5 14.2c-.9.95-.24 2.55 1.06 2.55h11.88c1.3 0 1.96-1.6 1.06-2.55l-1.44-1.58A2 2 0 0117 11.2V8a5 5 0 00-5-5z"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinejoin="round"
          />
          <path d="M9.5 19a2.5 2.5 0 005 0" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 bg-gold-deep text-paper text-[10px] leading-none rounded-full w-4 h-4 grid place-items-center">
            {unreadCount > 9 ? "9+" : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-80 max-h-96 overflow-y-auto bg-paper border border-line rounded-xl shadow-lg z-50">
          <div className="flex items-center justify-between px-4 py-3 border-b border-line">
            <p className="text-sm font-medium">Notifications</p>
            {unreadCount > 0 && (
              <button type="button" onClick={handleMarkAllRead} className="text-xs text-teal hover:underline">
                Mark all read
              </button>
            )}
          </div>
          {notifications.length === 0 ? (
            <p className="px-4 py-6 text-sm text-ink/50 italic text-center">No notifications yet.</p>
          ) : (
            <ul>
              {notifications.map((n) => (
                <li key={n.id} className="border-b border-line last:border-0">
                  <Link
                    href={n.link || "#"}
                    onClick={() => handleOpen(n.id)}
                    className={`block px-4 py-3 text-sm hover:bg-paper-dim transition-colors ${
                      n.read ? "" : "bg-teal/5"
                    }`}
                  >
                    <div className="flex items-start gap-2">
                      {!n.read && <span className="w-1.5 h-1.5 rounded-full bg-teal mt-1.5 shrink-0" />}
                      <div className={n.read ? "pl-3.5" : ""}>
                        <p className="font-medium">{n.title}</p>
                        {n.body && <p className="text-ink/60 text-xs mt-0.5">{n.body}</p>}
                        <p className="text-ink/40 text-[11px] mt-1">{new Date(n.createdAt).toLocaleString()}</p>
                      </div>
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

'@ | Set-Content -LiteralPath "src/components/notification-bell.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
"use client";

import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { logoutAction } from "@/app/actions/auth";

// How long a portal can sit idle before automatically logging out.
const IDLE_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

const ACTIVITY_EVENTS = ["mousemove", "mousedown", "keydown", "scroll", "touchstart"] as const;

export function IdleLogout() {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const router = useRouter();

  useEffect(() => {
    function resetTimer() {
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(async () => {
        // logoutAction() calls redirect() internally, which is reliable when
        // triggered by a form submission but not guaranteed when called from
        // a plain timer callback like this - so clear the cookie server-side
        // via the action, then always force the navigation client-side too,
        // regardless of what the action's own redirect does.
        try {
          await logoutAction();
        } catch {
          // redirect() throws by design - ignore and fall through.
        }
        router.push("/login?reason=inactivity");
        router.refresh();
      }, IDLE_TIMEOUT_MS);
    }

    resetTimer();
    ACTIVITY_EVENTS.forEach((event) => window.addEventListener(event, resetTimer));

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      ACTIVITY_EVENTS.forEach((event) => window.removeEventListener(event, resetTimer));
    };
  }, [router]);

  return null;
}

'@ | Set-Content -LiteralPath "src/components/idle-logout.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/components" | Out-Null
@'
﻿import Link from "next/link";
import { logoutAction } from "@/app/actions/auth";
import { NotificationBell } from "@/components/notification-bell";
import { IdleLogout } from "@/components/idle-logout";

export function PortalNav({
  role,
  name,
  links,
}: {
  role: string;
  name: string;
  links: { href: string; label: string }[];
}) {
  return (
    <header className="border-b border-line">
      <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between gap-6">
        <div className="flex items-center gap-8 min-w-0">
          <Link href="/" className="font-display text-lg shrink-0">
            WorldPath
          </Link>
          <nav className="hidden sm:flex items-center gap-5 text-sm overflow-x-auto">
            {links.map((l) => (
              <Link
                key={l.href}
                href={l.href}
                className="text-ink/70 hover:text-ink transition-colors whitespace-nowrap"
              >
                {l.label}
              </Link>
            ))}
          </nav>
        </div>
        <div className="flex items-center gap-3 text-sm shrink-0">
          <NotificationBell />
          <Link href="/account" className="text-ink/60 hover:text-ink transition-colors">
            {name} · <span className="uppercase text-xs tracking-wide">{role}</span>
          </Link>
          <form action={logoutAction}>
            <button className="text-teal hover:underline">Log out</button>
          </form>
        </div>
      </div>
      <IdleLogout />
    </header>
  );
}


'@ | Set-Content -LiteralPath "src/components/portal-nav.tsx" -Encoding utf8

New-Item -ItemType Directory -Force -Path "src/app/student" | Out-Null
@'
﻿import { getSession } from "@/lib/auth";
import { getStudentByUserId, getStaffById, listNotesForStudent } from "@/lib/repo";
import { APPLICATION_STATUSES } from "@/types";
import type { DocumentItem } from "@/types";
import { DocumentUploadRow } from "./document-upload-row";
import { MessageThread } from "@/components/message-thread";
import { MessageForm } from "@/components/message-form";
import { studentAddNoteAction } from "@/app/actions/student";
import { RequestFormButton } from "./request-form-button";

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
      <div className="flex items-center gap-4 mb-3">
        <div className="w-14 h-14 rounded-full bg-paper-dim border border-line overflow-hidden shrink-0">
          {student.photoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={student.photoUrl} alt={session?.name || ""} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full grid place-items-center text-ink/40">{session?.name?.charAt(0) ?? "?"}</div>
          )}
        </div>
        <p className="font-mono text-xs bg-paper-dim border border-line rounded px-2 py-1 inline-block">
          {student.code}
        </p>
      </div>
      <h1 className="font-display text-3xl mb-2">Welcome, {session?.name}</h1>
      <p className="text-ink/60 mb-10">
 {staff ? `Your counselor is ${staff.name}.` : "A counselor hasn't been assigned yet - one will be soon."}
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

      {student.applicationType === "standard" && student.assignedStaffId && (
        <div className="border border-gold-deep/30 bg-gold/5 rounded-xl p-5 mb-10 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <p className="font-medium mb-1">Need your application form?</p>
            <p className="text-sm text-ink/60">
              Standard applications start with a request to your counselor rather than a default
              checklist. They'll reply in your message thread with the form attached.
            </p>
          </div>
          <RequestFormButton />
        </div>
      )}

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

import { useActionState } from "react";
import { requestApplicationFormAction } from "@/app/actions/student";
import type { FormState } from "@/app/actions/auth";

const initialState: FormState = {};

export function RequestFormButton() {
  const [state, formAction, pending] = useActionState(async (_prev: FormState) => requestApplicationFormAction(), initialState);

  if (state.success) {
    return <p className="text-sm text-teal">{state.success}</p>;
  }

  return (
    <form action={formAction}>
      <button type="submit" disabled={pending} className="btn-secondary text-sm disabled:opacity-60">
        {pending ? "Requesting..." : "Request application form"}
      </button>
      {state.error && <p className="text-sm text-red-700 mt-2">{state.error}</p>}
    </form>
  );
}

'@ | Set-Content -LiteralPath "src/app/student/request-form-button.tsx" -Encoding utf8

git add -A
git commit -m "Add notifications, auto-logout, welcome email, and standard-application form request flow"
git push

Write-Host 'Done. Files written and pushed.'