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
            Ã—
          </button>
        </div>
      )}
    </>
  );
}

