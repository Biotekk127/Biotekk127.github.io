"use client";

import { useEffect, useState } from "react";
import { business } from "@/lib/business";
import { MannyBadge } from "./Manny";

export function Logo() {
  return (
    <span className="inline-flex items-center gap-2.5">
      <MannyBadge className="h-11 w-11" />
      <span className="font-display text-xl leading-none font-extrabold tracking-tight">
        Manny&apos;s<span className="text-red-bright">.</span>
        <span className="mt-1 block text-[0.6rem] font-semibold tracking-[0.28em] text-cream/60 uppercase">Landscaping</span>
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
    <header className={`fixed inset-x-0 top-0 z-50 text-cream transition-all duration-300 ${solid ? "bg-navy/90 backdrop-blur" : ""}`}>
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3.5 sm:px-8">
        <a href="#top" aria-label={`${business.name} home`}>
          <Logo />
        </a>
        <nav className="hidden items-center gap-8 text-sm font-medium md:flex">
          {links.map(([l, h]) => (
            <a key={h} href={h} className="text-cream/75 transition hover:text-red-bright">
              {l}
            </a>
          ))}
        </nav>
        <a href={business.phoneHref} className="rounded-xl bg-red px-4 py-2.5 text-sm font-bold text-cream transition hover:bg-red-bright">
          <span className="sm:hidden">Call</span>
          <span className="hidden sm:inline">{business.phone}</span>
        </a>
      </div>
    </header>
  );
}
