"use client";

import { useEffect, useState } from "react";
import { business } from "@/lib/business";

export function Logo() {
  return (
    <span className="inline-flex items-center gap-2.5">
      <svg viewBox="0 0 36 36" className="h-9 w-9" aria-hidden>
        <rect width="36" height="36" rx="10" fill="#8bd157" />
        <path d="M18 27 C18 18 12 14 8 13 C10 20 13 24 18 27 Z M18 27 C18 17 23 11 28 9 C27 18 23 24 18 27 Z" fill="#1b1e1c" />
      </svg>
      <span className="font-display text-xl leading-none font-extrabold tracking-tight">
        Manny&apos;s<span className="text-grass-light">.</span>
        <span className="mt-1 block text-[0.6rem] font-semibold tracking-[0.28em] text-stone/60 uppercase">Landscaping</span>
      </span>
    </span>
  );
}

const links = [
  ["Services", "#services"],
  ["Our work", "#work"],
  ["Reviews", "#reviews"],
  ["Contact", "#contact"],
];

export function Header() {
  const [solid, setSolid] = useState(false);
  useEffect(() => {
    const on = () => setSolid(window.scrollY > 30);
    on();
    window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);
  return (
    <header className={`fixed inset-x-0 top-0 z-50 text-stone transition-all duration-300 ${solid ? "bg-char/90 backdrop-blur" : ""}`}>
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3.5 sm:px-8">
        <a href="#top" aria-label={`${business.name} home`}>
          <Logo />
        </a>
        <nav className="hidden items-center gap-8 text-sm font-medium md:flex">
          {links.map(([l, h]) => (
            <a key={h} href={h} className="text-stone/75 transition hover:text-grass-light">
              {l}
            </a>
          ))}
        </nav>
        <a href={business.phoneHref} className="rounded-xl bg-grass-light px-4 py-2.5 text-sm font-bold text-char transition hover:bg-stone">
          <span className="sm:hidden">Call</span>
          <span className="hidden sm:inline">{business.phone}</span>
        </a>
      </div>
    </header>
  );
}
