"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { business } from "@/lib/business";

gsap.registerPlugin(ScrollTrigger);

export function Hero() {
  const root = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = root.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: "expo.out" } });
      tl.from(".hero-line > span", { yPercent: 115, duration: 1.4, stagger: 0.1 }, 0.1)
        .from(".hero-fade", { y: 24, opacity: 0, duration: 1.1, stagger: 0.08 }, 0.6)
        .fromTo(".hero-media", { clipPath: "inset(100% 0% 0% 0% round 1.75rem)" }, { clipPath: "inset(0% 0% 0% 0% round 1.75rem)", duration: 1.6 }, 0.45)
        .from(".hero-media img", { scale: 1.35, duration: 2.2 }, 0.45);
      gsap.to(".hero-media img", {
        yPercent: 10,
        scale: 1.08,
        ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
      gsap.to(".hero-title", {
        yPercent: -18,
        opacity: 0.25,
        ease: "none",
        scrollTrigger: { trigger: el, start: "top top", end: "bottom top", scrub: true },
      });
    }, el);
    return () => ctx.revert();
  }, []);

  const photo = business.photos[0];

  return (
    <section ref={root} id="top" className="grain relative overflow-hidden bg-navy pt-28 pb-10 text-cream sm:pt-36">
      <div className="pointer-events-none absolute top-0 right-0 h-[40rem] w-[40rem] translate-x-1/3 -translate-y-1/3 rounded-full bg-red/20 blur-[120px]" aria-hidden />

      <div className="relative mx-auto max-w-[88rem] px-4 sm:px-8">
        <div className="hero-fade flex items-center justify-between border-b border-cream/15 pb-5 text-cream/60">
          <span className="idx">(01) Landscaping &amp; Hardscape</span>
          <span className="idx hidden sm:block">Willimantic, Connecticut</span>
        </div>

        <h1 className="hero-title mt-10 font-display text-[clamp(3.4rem,11.5vw,11.5rem)] leading-[0.86] font-semibold tracking-[-0.055em]">
          <span className="hero-line block overflow-hidden pb-[0.06em]">
            <span className="block">Every cut,</span>
          </span>
          <span className="hero-line block overflow-hidden pb-[0.06em]">
            <span className="block">
              every <em className="font-serif font-normal tracking-[-0.02em] text-red-bright italic">detail.</em>
            </span>
          </span>
        </h1>

        <div className="mt-12 grid gap-10 lg:grid-cols-12 lg:gap-8">
          <div className="flex flex-col justify-between gap-10 lg:col-span-4">
            <p className="hero-fade max-w-sm text-lg leading-relaxed text-cream/70">
              Paver walkways, stone steps and year-round yard care, built by {business.ownerName} and his crew in{" "}
              {business.address.city}.
            </p>
            <div className="hero-fade flex flex-wrap items-center gap-3">
              <a data-magnetic href={business.phoneHref} className="inline-flex items-center gap-3 rounded-full bg-red py-2 pr-2 pl-6 font-medium text-cream transition-colors hover:bg-red-bright">
                Call {business.phone}
                <span className="grid h-10 w-10 place-items-center rounded-full bg-cream text-navy" aria-hidden>
                  ↗
                </span>
              </a>
              <a href="#contact" className="rounded-full px-5 py-4 font-medium text-cream/80 underline decoration-cream/30 underline-offset-8 transition hover:text-cream hover:decoration-cream">
                Request a quote
              </a>
            </div>
            <a href="#reviews" className="hero-fade flex items-center gap-4 border-t border-cream/15 pt-5 text-sm text-cream/60 hover:text-cream">
              <span className="font-display text-3xl font-semibold tracking-tight text-cream">{business.rating.toFixed(1)}</span>
              <span>
                <span className="text-red-bright">★★★★</span>
                <span className="text-cream/30">★</span>
                <br />
                {business.reviewCount} reviews on Google
              </span>
            </a>
          </div>

          <figure className="hero-media relative aspect-[16/10] overflow-hidden rounded-[1.75rem] lg:col-span-8">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={photo.src} alt={photo.alt} className="h-full w-full object-cover" fetchPriority="high" />
            <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-navy/60 via-transparent to-transparent" />
            <figcaption className="absolute right-5 bottom-5 left-5 flex items-end justify-between text-sm text-cream">
              <span className="font-serif text-2xl italic">Curved paver walkway</span>
              <span className="idx text-cream/70">Recent job</span>
            </figcaption>
          </figure>
        </div>
      </div>
    </section>
  );
}
