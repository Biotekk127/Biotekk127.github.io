"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { business } from "@/lib/business";
import { Stars } from "./Stars";

gsap.registerPlugin(ScrollTrigger);

/** Deterministic row of gabled houses as one silhouette path. */
function roofline(seed: number, width: number, base: number, minH: number, maxH: number) {
  let s = seed;
  const rnd = () => ((s = (s * 9301 + 49297) % 233280) / 233280);
  let x = -40;
  let d = `M ${x} ${base + 400} L ${x} ${base}`;
  while (x < width + 40) {
    const w = 120 + rnd() * 160;
    const wall = minH + rnd() * (maxH - minH);
    const pitch = 0.35 + rnd() * 0.35;
    const gap = rnd() * 30;
    const top = base - wall;
    const peak = top - (w / 2) * pitch;
    d += ` L ${x} ${top} L ${x + w / 2} ${peak} L ${x + w} ${top}`;
    if (rnd() > 0.6) d += ` L ${x + w * 0.78} ${top} L ${x + w * 0.78} ${top - 30} L ${x + w * 0.85} ${top - 30} L ${x + w * 0.85} ${top}`;
    d += ` L ${x + w} ${base} L ${x + w + gap} ${base}`;
    x += w + gap;
  }
  return d + ` L ${x} ${base + 400} Z`;
}

const LAYERS = [
  { d: roofline(7, 1600, 520, 60, 120), fill: "#1e3246", speed: 0.15 },
  { d: roofline(42, 1600, 600, 90, 170), fill: "#162638", speed: 0.35 },
  { d: roofline(99, 1600, 700, 120, 220), fill: "#0c1622", speed: 0.6 },
];

export function Hero() {
  const root = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const ctx = gsap.context(() => {
      gsap.from("[data-hero-in]", { y: 40, opacity: 0, duration: 1.1, ease: "power3.out", stagger: 0.12, delay: 0.15 });
      if (reduce) return;
      gsap.from(".hero-sun", { y: 120, opacity: 0, duration: 2.2, ease: "power2.out" });
      el.querySelectorAll<SVGPathElement>("[data-layer]").forEach((layer) => {
        const speed = Number(layer.dataset.layer);
        gsap.to(layer, {
          yPercent: speed * 18,
          ease: "none",
          scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
        });
      });
      gsap.to(".hero-copy", {
        yPercent: -35,
        opacity: 0,
        rotateX: 18,
        scale: 0.94,
        ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
    }, el);
    return () => ctx.revert();
  }, []);

  return (
    <section ref={root} id="top" className="grain relative isolate flex min-h-[100svh] items-center overflow-hidden bg-slate-ink text-bone">
      {/* dusk sky */}
      <div className="absolute inset-0 -z-20 bg-[radial-gradient(120%_80%_at_70%_85%,#d9822b55_0%,#1e3246_45%,#0c1622_100%)]" />
      <div className="hero-sun absolute right-[12%] bottom-[22%] -z-10 h-56 w-56 rounded-full bg-copper/60 blur-3xl sm:h-80 sm:w-80" />

      <svg className="absolute inset-x-0 bottom-0 -z-10 h-[75%] w-full" viewBox="0 0 1600 800" preserveAspectRatio="xMidYMax slice" aria-hidden>
        {LAYERS.map((l, i) => (
          <path key={i} d={l.d} fill={l.fill} data-layer={l.speed} />
        ))}
      </svg>
      <div className="vignette pointer-events-none absolute inset-0 -z-10" />

      <div className="hero-copy mx-auto w-full max-w-6xl px-4 pt-28 pb-40 [perspective:900px] sm:px-8">
        <p data-hero-in className="mb-5 inline-flex items-center gap-2 rounded-full border border-bone/20 bg-bone/5 px-4 py-1.5 text-xs font-semibold tracking-[0.2em] text-copper-light uppercase backdrop-blur">
          {business.address.city}, Connecticut · {business.category}
        </p>
        <h1 data-hero-in className="font-display text-[clamp(2.6rem,8vw,6.5rem)] leading-[0.92] font-black tracking-tight uppercase">
          Built to weather
          <br />
          <span className="text-copper">New England.</span>
        </h1>
        <p data-hero-in className="mt-6 max-w-xl text-lg text-bone/80 sm:text-xl">
          {business.tagline}. Honest estimates, clean job sites, and roofs that hold up to every nor&apos;easter.
        </p>
        <div data-hero-in className="mt-9 flex flex-col gap-3 sm:flex-row">
          <a href={business.phoneHref} className="rounded-md bg-copper px-7 py-4 text-center font-display text-lg font-extrabold tracking-wide text-slate-ink uppercase shadow-lg shadow-copper/30 transition hover:bg-copper-light">
            Call {business.phone}
          </a>
          <a href="#contact" className="rounded-md border border-bone/30 px-7 py-4 text-center font-display text-lg font-extrabold tracking-wide uppercase transition hover:border-bone hover:bg-bone/10">
            Free Estimate
          </a>
        </div>
        <a data-hero-in href="#reviews" className="mt-10 inline-flex items-center gap-3 text-sm text-bone/80 hover:text-bone">
          <Stars value={business.rating ?? 5} className="text-copper-light" />
          {business.rating && business.reviewCount ? (
            <span>
              <b>{business.rating.toFixed(1)}</b> on Google · {business.reviewCount} reviews
            </span>
          ) : (
            <span className="placeholder rounded px-2 py-0.5">[PLACEHOLDER] X.X on Google · N reviews</span>
          )}
        </a>
      </div>

      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 text-xs tracking-[0.3em] text-bone/50 uppercase">Scroll</div>
    </section>
  );
}
