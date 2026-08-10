"use client";

import { useActionState } from "react";
import { saveBlogPostAction, type FormState } from "@/app/actions/blog";
import { PhotoUploadField } from "@/components/photo-upload-field";

export function BlogPostForm({
  post,
}: {
  post?: {
    id: string;
    title: string;
    excerpt: string;
    body: string;
    coverImageUrl: string | null;
    tags: string;
    authorName: string;
    published: number;
  };
}) {
  const [state, formAction, pending] = useActionState<FormState, FormData>(saveBlogPostAction, {});
  const tags = post ? (JSON.parse(post.tags) as string[]).join(", ") : "";

  return (
    <form action={formAction} className="space-y-5 max-w-2xl">
      {post && <input type="hidden" name="id" value={post.id} />}

      <div>
        <span className="block text-sm font-medium mb-1.5">Cover image (optional)</span>
        <PhotoUploadField
          existingUrl={post?.coverImageUrl}
          name="cover"
          hiddenFieldName="existingCoverUrl"
          shape="rect"
        />
      </div>

      <Field label="Title">
        <input name="title" defaultValue={post?.title} required className="input" placeholder="e.g. How to apply for a need-based scholarship in the US" />
      </Field>

      <Field label="Excerpt (shown in previews and search results)">
        <textarea name="excerpt" defaultValue={post?.excerpt} required rows={2} className="input" />
      </Field>

      <Field label="Body (Markdown supported - headings, **bold**, lists, links)">
        <textarea name="body" defaultValue={post?.body} required rows={16} className="input font-mono text-sm" />
      </Field>

      <div className="grid sm:grid-cols-2 gap-5">
        <Field label="Author name">
          <input name="authorName" defaultValue={post?.authorName || "WorldPath Group"} required className="input" />
        </Field>
        <Field label="Tags (comma-separated)">
          <input name="tags" defaultValue={tags} className="input" placeholder="scholarships, USA, essays" />
        </Field>
      </div>

      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="published" defaultChecked={post ? post.published === 1 : false} className="accent-teal" />
        Published (visible on the public blog)
      </label>

      {state.error && <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg px-4 py-3">{state.error}</p>}
      {state.success && <p className="text-sm text-teal bg-teal/10 border border-teal/30 rounded-lg px-4 py-3">{state.success}</p>}

      <button type="submit" disabled={pending} className="btn-primary disabled:opacity-60">
        {pending ? "Saving..." : post ? "Save changes" : "Create post"}
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
