"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { business } from "@/lib/business";

gsap.registerPlugin(ScrollTrigger);

/** Line drawing of a Victorian house; each path "draws" itself in. */
const LINES = [
  "M20 470 H580", // ground
  "M200 470 V232 H450 V470", // main body
  "M180 242 L325 100 L470 242", // main gable
  "M110 470 V215 H200", // tower walls
  "M100 220 L155 95 L210 220", // tower cone
  "M155 95 V70", // finial
  "M392 152 V96 H420 V180", // chimney
  "M384 96 H428", // chimney cap
  "M190 380 H462 M200 380 L215 360 H445 L460 380", // porch roof
  "M215 380 V470 M300 380 V470 M445 380 V470", // posts
  "M300 470 V408 H340 V470", // door
  "M235 270 H280 V330 H235 Z M370 270 H415 V330 H370 Z", // upper windows
  "M235 405 H275 V450 H235 Z M370 405 H415 V450 H370 Z", // lower windows
  "M130 260 H180 V320 H130 Z M130 380 H180 V440 H130 Z", // tower windows
  "M215 440 H285 M355 440 H430", // porch rail
];

export function Hero() {
  const root = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const ctx = gsap.context(() => {
      gsap.from("[data-hero-in]", { y: 30, opacity: 0, duration: 1, ease: "power3.out", stagger: 0.1, delay: 0.1 });
      if (reduce) return;
      el.querySelectorAll<SVGPathElement>(".draw").forEach((p, i) => {
        const len = p.getTotalLength();
        gsap.fromTo(p, { strokeDasharray: len, strokeDashoffset: len }, { strokeDashoffset: 0, duration: 1.4, ease: "power2.inOut", delay: 0.3 + i * 0.09 });
      });
      gsap.from(".gable-window", { scale: 0, transformOrigin: "50% 50%", duration: 0.8, ease: "back.out(2)", delay: 1.6 });
      // scroll: new roof "goes on" over the gable, house rises & tilts in 3D
      // the new roof "goes on" once the house has drawn itself
      gsap.from(".roof-fill", { scaleY: 0, transformOrigin: "50% 100%", duration: 1.4, ease: "power2.out", delay: 1.9 });
      gsap.to(".house", {
        yPercent: -8, rotateY: -10, rotateX: 6, ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
    }, el);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={root} id="top" className="drafting relative overflow-hidden border-b border-forest/15 pt-28 pb-16 sm:pt-36 sm:pb-24">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-4 sm:px-8 lg:grid-cols-[1.05fr_1fr]">
        <div>
          <p data-hero-in className="text-sm font-semibold tracking-[0.22em] text-brick uppercase">
            {business.address.city}, Connecticut
          </p>
          <h1 data-hero-in className="mt-5 font-serif text-[clamp(2.8rem,7vw,5.6rem)] leading-[0.98] font-semibold tracking-tight text-forest">
            Top-notch roofs for <em className="font-normal text-brick">homes old</em> &amp; new.
          </h1>
          <p data-hero-in className="mt-6 max-w-lg text-lg leading-relaxed text-ink/75">
            {business.name} replaces and repairs roofs across the Willimantic area, including the steep, tricky roofs
            on older houses.
          </p>
          <div data-hero-in className="mt-9 flex flex-col gap-3 sm:flex-row">
            <a href={business.phoneHref} className="rounded-full bg-forest px-8 py-4 text-center font-semibold text-paper shadow-lg shadow-forest/25 transition hover:bg-forest-light">
              Call {business.phone}
            </a>
            <a href="#contact" className="rounded-full border-2 border-forest px-8 py-4 text-center font-semibold text-forest transition hover:bg-forest hover:text-paper">
              Request a quote
            </a>
          </div>
          <figure data-hero-in className="mt-10 max-w-md border-l-2 border-brass pl-5">
            <blockquote className="font-serif text-lg text-ink/85 italic">&ldquo;{business.reviews[0].text.replace(/\s+/g, " ")}&rdquo;</blockquote>
            <figcaption className="mt-2 text-sm text-ink/60">
              <span className="text-brass">★★★★★</span> {business.reviews[0].name}, Google review
            </figcaption>
          </figure>
        </div>

        <div className="relative [perspective:1000px]" aria-hidden>
          <div className="absolute inset-6 rounded-full bg-brass/20 blur-3xl" />
          <svg viewBox="0 0 600 500" className="house relative w-full">
            <defs>
              <pattern id="shingle" width="22" height="14" patternUnits="userSpaceOnUse">
                <rect width="22" height="14" fill="#a8432a" />
                <path d="M0 13.5 H22 M11 0 V7 M0 7 H22 M5 7 V14 M16 7 V14" stroke="#7d2f1d" strokeWidth="1.2" />
              </pattern>
              <clipPath id="gable">
                <path d="M180 242 L325 100 L470 242 Z M100 220 L155 95 L210 220 Z" />
              </clipPath>
            </defs>
            <g clipPath="url(#gable)">
              <rect className="roof-fill" x="90" y="90" width="390" height="155" fill="url(#shingle)" />
            </g>
            <g fill="none" stroke="#2e4a3b" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round">
              {LINES.map((d, i) => (
                <path key={i} className="draw" d={d} />
              ))}
            </g>
            <circle className="gable-window" cx="325" cy="190" r="20" fill="#f3ece0" stroke="#2e4a3b" strokeWidth="4" />
          </svg>
        </div>
      </div>
    </section>
  );
}
