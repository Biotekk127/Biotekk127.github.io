"use client";

/**
 * Cinematic 3D scroll of the storefront, driven by an image sequence
 * extracted from the client's video (see scripts/extract-frames.sh).
 * Scrolling scrubs through the frames on a <canvas> while the frame
 * gets a slight perspective tilt + zoom and headlines fade in at key points.
 */
import { useEffect, useRef, useState } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export type FrameManifest = { count: number; pattern: string; mobilePattern?: string; width: number; height: number };
export type Beat = { at: number; kicker?: string; title: string };

export function ScrollSequence({ manifest, beats }: { manifest: FrameManifest; beats: Beat[] }) {
  const section = useRef<HTMLElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const [loaded, setLoaded] = useState(0);
  const [mode, setMode] = useState<"scrub" | "still">("scrub");

  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      setMode("still");
      return;
    }
    const small = window.innerWidth < 768;
    const pattern = small && manifest.mobilePattern ? manifest.mobilePattern : manifest.pattern;
    const src = (i: number) => pattern.replace("%04d", String(i + 1).padStart(4, "0"));
    const frames: HTMLImageElement[] = [];
    const cv = canvas.current!;
    const ctx2d = cv.getContext("2d")!;
    let current = 0;
    let count = 0;

    const draw = (i: number) => {
      let img = frames[i];
      // fall back to nearest loaded frame while the rest stream in
      for (let k = i; (!img || !img.complete) && k >= 0; k--) img = frames[k];
      if (!img || !img.complete || !img.naturalWidth) return;
      const { width: cw, height: ch } = cv;
      const scale = Math.max(cw / img.naturalWidth, ch / img.naturalHeight);
      const w = img.naturalWidth * scale;
      const h = img.naturalHeight * scale;
      ctx2d.drawImage(img, (cw - w) / 2, (ch - h) / 2, w, h);
    };

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      cv.width = cv.clientWidth * dpr;
      cv.height = cv.clientHeight * dpr;
      draw(current);
    };

    // first 12 frames eagerly, the rest after
    for (let i = 0; i < manifest.count; i++) {
      const img = new Image();
      img.decoding = "async";
      img.onload = () => {
        count++;
        setLoaded(count);
        if (i === 0 || i === current) draw(current);
      };
      frames[i] = img;
      if (i < 12) img.src = src(i);
    }
    const lazy = window.setTimeout(() => frames.forEach((f, i) => i >= 12 && (f.src = src(i))), 300);

    resize();
    window.addEventListener("resize", resize);

    const gctx = gsap.context(() => {
      const state = { f: 0 };
      const tl = gsap.timeline({
        scrollTrigger: { trigger: section.current, start: "top top", end: "bottom bottom", scrub: 0.6 },
      });
      tl.to(state, {
        f: manifest.count - 1,
        ease: "none",
        duration: 1,
        onUpdate: () => {
          current = Math.round(state.f);
          draw(current);
        },
      }, 0);
      tl.fromTo(".seq-frame", { rotateX: 8, scale: 1.12 }, { rotateX: 0, scale: 1, ease: "power1.out", duration: 1 }, 0);
      beats.forEach((b, i) => {
        const sel = `.seq-beat-${i}`;
        tl.fromTo(sel, { opacity: 0, y: 40 }, { opacity: 1, y: 0, duration: 0.08 }, b.at);
        tl.to(sel, { opacity: 0, y: -40, duration: 0.08 }, Math.min(b.at + 0.2, 0.98));
      });
    }, section);

    return () => {
      window.clearTimeout(lazy);
      window.removeEventListener("resize", resize);
      gctx.revert();
    };
  }, [manifest, beats]);

  if (mode === "still") {
    return (
      <section id="top" className="relative flex min-h-[100svh] items-end bg-char text-stone">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={manifest.pattern.replace("%04d", "0001")} alt="Storefront" className="absolute inset-0 h-full w-full object-cover" />
        <div className="vignette absolute inset-0" />
        <h1 className="relative p-8 font-display text-5xl font-black uppercase">{beats[0]?.title}</h1>
      </section>
    );
  }

  return (
    <section ref={section} id="top" className="relative h-[450vh] bg-char text-stone">
      <div className="sticky top-0 h-[100svh] overflow-hidden [perspective:1200px]">
        <div className="seq-frame grain absolute inset-0 origin-bottom">
          <canvas ref={canvas} className="h-full w-full" aria-label="Cinematic walk-up to the storefront" role="img" />
        </div>
        <div className="vignette pointer-events-none absolute inset-0" />
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-char/80 via-transparent to-char/40" />
        {beats.map((b, i) => (
          <div key={i} className={`seq-beat-${i} absolute inset-x-0 bottom-[18%] mx-auto max-w-5xl px-4 opacity-0 sm:px-8`}>
            {b.kicker && <p className="mb-3 text-sm font-semibold tracking-[0.25em] text-grass-light uppercase">{b.kicker}</p>}
            <h2 className="font-display text-[clamp(2.4rem,7vw,6rem)] leading-[0.95] font-black tracking-tight uppercase">{b.title}</h2>
          </div>
        ))}
        {loaded < Math.min(12, manifest.count) && (
          <div className="absolute inset-0 grid place-items-center bg-char">
            <div className="h-1 w-48 overflow-hidden rounded bg-stone/10">
              <div className="h-full bg-grass transition-all" style={{ width: `${(loaded / Math.min(12, manifest.count)) * 100}%` }} />
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
