import { notFound } from "next/navigation";
import { getPostById } from "@/lib/repo";
import { BlogPostForm } from "../blog-form";

export const dynamic = "force-dynamic";

export default async function EditBlogPostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = getPostById(id);
  if (!post) notFound();

  return (
    <div>
      <h1 className="font-display text-3xl mb-8">Edit blog post</h1>
      <BlogPostForm post={post} />
    </div>
  );
}
