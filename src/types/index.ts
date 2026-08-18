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

export type ApplicationTrack = "university" | "work_visa";

export const YEARS_EXPERIENCE_OPTIONS = [
  "Less than 1 year",
  "1-3 years",
  "3-5 years",
  "5-10 years",
  "10+ years",
];

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
  applicationTrack: ApplicationTrack;
  profession: string;
  currentOccupation: string;
  yearsExperience: string;
  hasJobOffer: number;
  phone: string;
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
  workVisaInfo: string;
  workVisaHeroImageUrl: string | null;
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

export type JobVerificationStatus =
  | "verified"
  | "employer_source"
  | "government_source"
  | "pending_verification"
  | "expired";

export const JOB_VERIFICATION_LABELS: Record<JobVerificationStatus, string> = {
  verified: "Verified",
  employer_source: "Employer Source",
  government_source: "Government/Official Source",
  pending_verification: "Pending Verification",
  expired: "Expired",
};

export const JOB_COUNTRIES = ["USA", "Germany", "Other"];

export interface JobRecord {
  id: string;
  title: string;
  employer: string;
  country: string;
  city: string;
  industry: string;
  employmentType: string;
  experienceRequired: string;
  educationRequirement: string;
  languageRequirement: string;
  salary: string;
  sponsorshipInfo: string;
  applicationDeadline: string | null;
  lastVerifiedDate: string | null;
  source: string;
  verificationStatus: JobVerificationStatus;
  applicationUrl: string;
  description: string;
  published: number;
  createdAt: string;
  updatedAt: string;
}

export type JobApplicationStatus =
  | "saved"
  | "preparing"
  | "applied"
  | "employer_review"
  | "interview"
  | "offer_received"
  | "accepted"
  | "not_selected"
  | "withdrawn";

export const JOB_APPLICATION_STATUSES: { value: JobApplicationStatus; label: string }[] = [
  { value: "saved", label: "Saved" },
  { value: "preparing", label: "Preparing" },
  { value: "applied", label: "Applied" },
  { value: "employer_review", label: "Employer Review" },
  { value: "interview", label: "Interview" },
  { value: "offer_received", label: "Offer Received" },
  { value: "accepted", label: "Accepted" },
  { value: "not_selected", label: "Not Selected" },
  { value: "withdrawn", label: "Withdrawn" },
];

export interface JobApplicationRecord {
  id: string;
  studentId: string;
  jobId: string;
  status: JobApplicationStatus;
  notes: string;
  createdAt: string;
  updatedAt: string;
}
