"use client";

import { useEffect, useState } from "react";
import { business } from "@/lib/business";

const links = [
  ["About", "#about"],
  ["Services", "#services"],
  ["Reviews", "#reviews"],
  ["Work", "#work"],
  ["Contact", "#contact"],
];

export function Logo({ className = "" }: { className?: string }) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <svg viewBox="0 0 40 32" className="h-7 w-9" aria-hidden>
        <path d="M2 18 L20 3 L38 18" fill="none" stroke="#d9822b" strokeWidth="4.5" strokeLinecap="square" />
        <path d="M9 17 V29 H31 V17" fill="none" stroke="currentColor" strokeWidth="3.5" />
      </svg>
      <span className="font-display leading-none font-black tracking-tight uppercase">
        <span className="block text-lg">CT Homes</span>
        <span className="block text-[0.62rem] tracking-[0.32em] text-copper">and Roofing</span>
      </span>
    </span>
  );
}

export function Header() {
  const [solid, setSolid] = useState(false);
  useEffect(() => {
    const on = () => setSolid(window.scrollY > 40);
    on();
    window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 text-bone transition-all duration-300 ${
        solid ? "bg-slate-ink/90 shadow-lg shadow-black/20 backdrop-blur" : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:h-20 sm:px-8">
        <a href="#top" aria-label={`${business.name} home`}>
          <Logo />
        </a>
        <nav className="hidden items-center gap-7 text-sm font-semibold md:flex">
          {links.map(([label, href]) => (
            <a key={href} href={href} className="text-bone/80 transition hover:text-copper-light">
              {label}
            </a>
          ))}
        </nav>
        <a href={business.phoneHref} className="rounded-md bg-copper px-4 py-2.5 font-display text-sm font-extrabold tracking-wide text-slate-ink uppercase transition hover:bg-copper-light">
          <span className="sm:hidden">Call Now</span>
          <span className="hidden sm:inline">{business.phone}</span>
        </a>
      </div>
    </header>
  );
}
