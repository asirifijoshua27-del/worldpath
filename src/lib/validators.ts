import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  targetLevel: z.enum(["undergrad", "masters", "phd"]),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
  scholarshipInterest: z.boolean(),
  currentEducationLevel: z.enum(["shs_graduate", "tertiary", "graduate", "other"]),
});

export const freeRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  schoolName: z.string().min(2, "Enter your school's name"),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination"),
});

export const workVisaRegisterSchema = z.object({
  name: z.string().min(2, "Enter your full name"),
  email: z.string().email("Enter a valid email address"),
  phone: z.string().min(9, "Enter a valid phone number"),
  profession: z.string().min(2, "Enter your profession or field"),
  currentOccupation: z.string().optional().default(""),
  yearsExperience: z.string().min(1, "Select your years of experience"),
  hasJobOffer: z.boolean(),
  targetCountries: z.array(z.string()).min(1, "Choose at least one destination country"),
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
  workVisaInfo: z.string().optional().default(""),
  workVisaHeroImageUrl: z.string().optional().default(""),
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

export const jobSchema = z.object({
  title: z.string().min(2, "Enter a job title"),
  employer: z.string().min(2, "Enter the employer name"),
  country: z.string().min(1, "Select a country"),
  city: z.string().optional().default(""),
  industry: z.string().optional().default(""),
  employmentType: z.string().optional().default(""),
  experienceRequired: z.string().optional().default(""),
  educationRequirement: z.string().optional().default(""),
  languageRequirement: z.string().optional().default(""),
  salary: z.string().optional().default(""),
  sponsorshipInfo: z.string().optional().default(""),
  applicationDeadline: z.string().optional().default(""),
  lastVerifiedDate: z.string().optional().default(""),
  source: z.string().optional().default(""),
  verificationStatus: z.enum(["verified", "employer_source", "government_source", "pending_verification", "expired"]),
  applicationUrl: z.string().optional().default(""),
  description: z.string().optional().default(""),
  published: z.boolean(),
});
