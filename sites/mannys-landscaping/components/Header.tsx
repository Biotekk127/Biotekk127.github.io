"use client";

import { useEffect, useState } from "react";
import { business } from "@/lib/business";

export function Wordmark({ className = "" }: { className?: string }) {
  return (
    <span className={`inline-flex items-baseline gap-2 ${className}`}>
      <span className="font-display text-xl font-semibold tracking-[-0.03em]">
        Manny&apos;s<span className="text-red-bright">.</span>
      </span>
      <span className="hidden font-serif text-base italic opacity-60 sm:inline">landscaping &amp; hardscape</span>
    </span>
  );
}

const links = [
  ["Services", "#services"],
  ["Work", "#work"],
  ["Reviews", "#reviews"],
  ["About", "#about"],
];

export function Header() {
  const [solid, setSolid] = useState(false);
  useEffect(() => {
    const on = () => setSolid(window.scrollY > 40);
    on();
    window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);
  return (
    <header className="fixed inset-x-0 top-0 z-50 px-3 pt-3 text-cream sm:px-5">
      <div
        className={`mx-auto flex max-w-[88rem] items-center justify-between rounded-full px-4 py-2.5 transition-all duration-500 sm:px-6 ${
          solid ? "bg-navy/75 shadow-2xl shadow-black/20 ring-1 ring-cream/10 backdrop-blur-xl" : ""
        }`}
      >
        <a href="#top" aria-label={`${business.name} home`}>
          <Wordmark />
        </a>
        <nav className="hidden items-center gap-1 text-sm md:flex">
          {links.map(([l, h]) => (
            <a key={h} href={h} className="rounded-full px-4 py-2 text-cream/70 transition hover:bg-cream/10 hover:text-cream">
              {l}
            </a>
          ))}
        </nav>
        <a href="#contact" className="rounded-full bg-cream px-5 py-2.5 text-sm font-medium text-navy transition hover:bg-red hover:text-cream">
          Get a quote
        </a>
      </div>
    </header>
  );
}
