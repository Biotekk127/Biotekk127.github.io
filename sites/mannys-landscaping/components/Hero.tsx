"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { business } from "@/lib/business";

gsap.registerPlugin(ScrollTrigger);

const COLS = 5;
const ROWS = 6;

export function Hero() {
  const root = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const ctx = gsap.context(() => {
      gsap.from("[data-hero-in]", { y: 36, opacity: 0, duration: 1, ease: "power3.out", stagger: 0.1 });
      if (reduce) {
        gsap.set(".paver-tile", { opacity: 0 });
        return;
      }
      // photo revealed paver by paver, laid from the bottom of the path up
      gsap.to(".paver-tile", {
        opacity: 0,
        scale: 0.6,
        rotateX: 70,
        duration: 0.55,
        ease: "power2.in",
        stagger: { grid: [ROWS, COLS], from: "end", amount: 1.3 },
        delay: 0.3,
      });
      gsap.from(".hero-photo img", { scale: 1.25, duration: 2.6, ease: "power2.out", delay: 0.2 });
      // scroll: path tilts back in 3D like you're stepping onto it
      gsap.to(".hero-photo", {
        rotateX: 22,
        y: 60,
        ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
      gsap.to(".hero-photo img", {
        scale: 1.15,
        ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
    }, el);
    return () => ctx.revert();
  }, []);

  const photo = business.photos[0];

  return (
    <section ref={root} id="top" className="relative overflow-hidden bg-char pt-24 pb-16 text-stone sm:pt-32 sm:pb-24">
      <div className="pointer-events-none absolute -top-40 -left-40 h-[36rem] w-[36rem] rounded-full bg-grass/25 blur-3xl" aria-hidden />
      <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 sm:px-8 lg:grid-cols-[1.15fr_1fr]">
        <div>
          <p data-hero-in className="inline-flex items-center gap-2 rounded-full bg-grass/15 px-4 py-1.5 text-sm font-medium text-grass-light">
            <span className="h-2 w-2 rounded-full bg-grass-light" /> Landscaping &amp; hardscape · {business.address.city}, CT
          </p>
          <h1 data-hero-in className="mt-6 font-display text-[clamp(3rem,8.5vw,6.8rem)] leading-[0.9] font-extrabold tracking-tight">
            Every cut,
            <br />
            <span className="text-grass-light">every detail.</span>
          </h1>
          <p data-hero-in className="mt-7 max-w-lg text-lg leading-relaxed text-stone/75">
            Paver walkways, stone steps, landscaping and seasonal yard care from {business.ownerName} and his crew in{" "}
            {business.address.city}.
          </p>
          <div data-hero-in className="mt-9 flex flex-col gap-3 sm:flex-row">
            <a href={business.phoneHref} className="rounded-xl bg-grass-light px-7 py-4 text-center font-display text-lg font-bold text-char transition hover:bg-stone">
              Call {business.phone}
            </a>
            <a href="#contact" className="rounded-xl border border-stone/25 px-7 py-4 text-center font-display text-lg font-bold transition hover:border-stone hover:bg-stone/10">
              Get a quote
            </a>
          </div>
        </div>

        <div className="[perspective:1100px]">
          <figure data-hero-in className="hero-photo relative aspect-[850/815] origin-bottom overflow-hidden rounded-3xl shadow-2xl shadow-black/50 ring-1 ring-stone/10">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={photo.src} alt={photo.alt} className="h-full w-full object-cover" fetchPriority="high" />
            <div className="pointer-events-none absolute inset-0 grid [perspective:600px]" style={{ gridTemplateColumns: `repeat(${COLS},1fr)`, gridTemplateRows: `repeat(${ROWS},1fr)` }} aria-hidden>
              {Array.from({ length: COLS * ROWS }, (_, i) => (
                <span key={i} className="paver-tile border border-char/60 bg-slate" />
              ))}
            </div>
            <figcaption className="absolute bottom-4 left-4 rounded-full bg-char/80 px-4 py-2 text-sm text-stone backdrop-blur">
              Paver walkway · recent job
            </figcaption>
          </figure>
        </div>
      </div>
    </section>
  );
}
