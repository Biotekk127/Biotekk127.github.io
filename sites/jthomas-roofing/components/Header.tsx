"use client";

import { useEffect, useState } from "react";
import { business } from "@/lib/business";

export function Logo({ light = false }: { light?: boolean }) {
  return (
    <span className="inline-flex items-center gap-3">
      <span className={`grid h-10 w-10 place-items-center rounded-full border-2 font-serif text-lg font-semibold ${light ? "border-brass text-brass" : "border-forest text-forest"}`}>
        JT
      </span>
      <span className="leading-none">
        <span className={`block font-serif text-xl font-semibold ${light ? "text-paper" : "text-forest"}`}>JThomas</span>
        <span className="block text-[0.65rem] font-semibold tracking-[0.3em] text-brick uppercase">Roofing</span>
      </span>
    </span>
  );
}

const links = [
  ["Services", "#services"],
  ["Review", "#review"],
  ["Work", "#work"],
  ["Visit", "#location"],
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
    <header className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${solid ? "bg-paper/90 shadow-md shadow-forest/10 backdrop-blur" : ""}`}>
      <div className="mx-auto flex h-18 max-w-6xl items-center justify-between px-4 py-3 sm:px-8">
        <a href="#top" aria-label={`${business.name} home`}>
          <Logo />
        </a>
        <nav className="hidden items-center gap-8 text-sm font-medium md:flex">
          {links.map(([l, h]) => (
            <a key={h} href={h} className="text-ink/75 transition hover:text-brick">
              {l}
            </a>
          ))}
        </nav>
        <a href={business.phoneHref} className="rounded-full bg-brick px-5 py-2.5 text-sm font-semibold text-paper transition hover:bg-forest">
          <span className="sm:hidden">Call</span>
          <span className="hidden sm:inline">{business.phone}</span>
        </a>
      </div>
    </header>
  );
}
