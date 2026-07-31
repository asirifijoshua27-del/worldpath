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
          <p className="text-ink/50 text-xs mt-0.5">JPG, PNG, WEBP, or GIF â€” up to 5MB</p>
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

