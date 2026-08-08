interface JourneyStep {
  title: string;
  body: string;
}

export function JourneyPath({ steps }: { steps: JourneyStep[] }) {
  return (
    <div className="w-full overflow-x-auto">
      <div className="relative min-w-[900px] pt-6 pb-2">
        <svg
          viewBox="0 0 1000 60"
          preserveAspectRatio="none"
          className="absolute left-0 right-0 top-10 w-full h-16 pointer-events-none"
          aria-hidden="true"
        >
          <path
            d="M20,30 C 120,-10 130,70 230,30 C 330,-10 340,70 440,30 C 540,-10 550,70 650,30 C 750,-10 760,70 860,30 C 900,10 940,30 980,30"
            fill="none"
            stroke="var(--color-teal)"
            strokeOpacity="0.5"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
        </svg>
        <div className="relative flex justify-between">
          {steps.map((step, i) => (
            <div
              key={step.title}
              className={`flex flex-col items-center text-center w-[180px] ${i % 2 === 1 ? "mt-10" : ""}`}
            >
              <span className="w-4 h-4 rounded-full bg-gold-deep border-2 border-paper" />
              <p className="font-display text-base mt-3 mb-1">{step.title}</p>
              <p className="text-xs text-ink/60 leading-relaxed">{step.body}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

