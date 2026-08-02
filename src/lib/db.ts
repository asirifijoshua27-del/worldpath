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

