const DESTINATIONS = ["USA", "Canada", "UK", "Germany", "Asia"];

// Signature hero element: a dashed route line connecting Ghana to each study
// destination, like a flight path. Styled for use on the dark navy hero.
export function PathRoute() {
  return (
    <div className="w-full overflow-x-auto">
      <div className="flex items-center justify-center gap-0 min-w-max py-6 mx-auto">
        <Stop label="Ghana" emphasized />
        {DESTINATIONS.map((d) => (
          <div key={d} className="flex items-center">
            <div className="w-10 sm:w-16 h-px border-t-2 border-dashed border-paper/30 mx-1" />
            <Stop label={d} />
          </div>
        ))}
      </div>
    </div>
  );
}

function Stop({ label, emphasized = false }: { label: string; emphasized?: boolean }) {
  return (
    <div className="flex flex-col items-center gap-2">
      <span className={emphasized ? "w-3 h-3 rounded-full bg-gold" : "w-2 h-2 rounded-full bg-paper/50"} />
      <span
        className={
          emphasized
            ? "font-display text-sm sm:text-base whitespace-nowrap text-paper"
            : "text-xs sm:text-sm whitespace-nowrap text-paper/60"
        }
      >
        {label}
      </span>
    </div>
  );
}
