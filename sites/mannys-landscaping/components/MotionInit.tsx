"use client";

/**
 * Site-wide motion system:
 *  - Lenis smooth scrolling, synced to GSAP ScrollTrigger
 *  - [data-split]   headings reveal line by line through a mask
 *  - [data-words]   paragraph lights up word by word as you scroll
 *  - [data-clip]    images wipe open with a clip-path, then drift (parallax)
 *  - [data-reveal]  simple fade + lift
 *  - [data-magnetic] buttons follow the cursor slightly
 * Everything is skipped under prefers-reduced-motion.
 */
import { useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SplitText } from "gsap/SplitText";
import Lenis from "lenis";

gsap.registerPlugin(ScrollTrigger, SplitText);

export function MotionInit() {
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const lenis = new Lenis({ duration: 1.15, anchors: { offset: -72 } });
    lenis.on("scroll", ScrollTrigger.update);
    const raf = (t: number) => lenis.raf(t * 1000);
    gsap.ticker.add(raf);
    gsap.ticker.lagSmoothing(0);

    let ctx: gsap.Context | undefined;
    const cleanups: (() => void)[] = [];

    document.fonts.ready.then(() => {
      ctx = gsap.context(() => {
        gsap.utils.toArray<HTMLElement>("[data-split]").forEach((el) => {
          SplitText.create(el, {
            type: "lines",
            mask: "lines",
            autoSplit: true,
            onSplit: (self) =>
              gsap.from(self.lines, {
                yPercent: 110,
                duration: 1.1,
                ease: "expo.out",
                stagger: 0.09,
                delay: Number(el.dataset.split || 0),
                scrollTrigger: { trigger: el, start: "top 88%", once: true },
              }),
          });
        });

        gsap.utils.toArray<HTMLElement>("[data-words]").forEach((el) => {
          const split = SplitText.create(el, { type: "words" });
          gsap.fromTo(
            split.words,
            { opacity: 0.14 },
            { opacity: 1, stagger: 0.05, ease: "none", scrollTrigger: { trigger: el, start: "top 80%", end: "bottom 45%", scrub: true } },
          );
        });

        gsap.utils.toArray<HTMLElement>("[data-clip]").forEach((el) => {
          const img = el.querySelector("img");
          gsap.fromTo(
            el,
            { clipPath: "inset(18% 12% 18% 12% round 1.5rem)" },
            { clipPath: "inset(0% 0% 0% 0% round 1.5rem)", duration: 1.5, ease: "expo.out", scrollTrigger: { trigger: el, start: "top 85%", once: true } },
          );
          if (img)
            gsap.fromTo(img, { scale: 1.25, yPercent: -6 }, { scale: 1.05, yPercent: 6, ease: "none", scrollTrigger: { trigger: el, start: "top bottom", end: "bottom top", scrub: true } });
        });

        gsap.utils.toArray<HTMLElement>("[data-reveal]").forEach((el) => {
          gsap.from(el, {
            y: 40,
            opacity: 0,
            duration: 1,
            ease: "expo.out",
            delay: Number(el.dataset.reveal || 0),
            scrollTrigger: { trigger: el, start: "top 90%", once: true },
          });
        });
      });
      ScrollTrigger.refresh();
    });

    if (window.matchMedia("(pointer: fine)").matches) {
      document.querySelectorAll<HTMLElement>("[data-magnetic]").forEach((el) => {
        const x = gsap.quickTo(el, "x", { duration: 0.5, ease: "power3.out" });
        const y = gsap.quickTo(el, "y", { duration: 0.5, ease: "power3.out" });
        const move = (e: MouseEvent) => {
          const r = el.getBoundingClientRect();
          x((e.clientX - r.left - r.width / 2) * 0.3);
          y((e.clientY - r.top - r.height / 2) * 0.4);
        };
        const leave = () => {
          x(0);
          y(0);
        };
        el.addEventListener("mousemove", move);
        el.addEventListener("mouseleave", leave);
        cleanups.push(() => {
          el.removeEventListener("mousemove", move);
          el.removeEventListener("mouseleave", leave);
        });
      });
    }

    return () => {
      cleanups.forEach((c) => c());
      ctx?.revert();
      gsap.ticker.remove(raf);
      lenis.destroy();
    };
  }, []);
  return null;
}
