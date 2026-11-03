import fs from "node:fs";
import path from "node:path";
import { business, fullAddress, PLACEHOLDER } from "@/lib/business";
import { Header, Logo } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { ScrollSequence, type FrameManifest } from "@/components/ScrollSequence";
import { MotionInit } from "@/components/MotionInit";
import { ContactForm } from "@/components/ContactForm";
import { Stars } from "@/components/Stars";

function readFrames(): FrameManifest | null {
  const file = path.join(process.cwd(), "public/frames/manifest.json");
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : null;
}

function Ph({ children }: { children: React.ReactNode }) {
  return <span className="placeholder rounded px-2 py-0.5">{PLACEHOLDER} {children}</span>;
}

function Heading({ kicker, children, light = false }: { kicker: string; children: React.ReactNode; light?: boolean }) {
  return (
    <div className="max-w-3xl">
      <p data-reveal className={`font-display text-sm font-bold tracking-[0.2em] uppercase ${light ? "text-grass-light" : "text-grass"}`}>
        {kicker}
      </p>
      <h2 data-reveal className="mt-3 font-display text-[clamp(2.3rem,5.5vw,4.2rem)] leading-[0.95] font-extrabold tracking-tight">
        {children}
      </h2>
    </div>
  );
}

const tagColor: Record<string, string> = {
  Hardscape: "bg-slate text-white",
  Spring: "bg-grass-light text-char",
  Summer: "bg-grass text-white",
  Fall: "bg-sand text-char",
};

export default function Page() {
  const frames = readFrames();
  const r = business.featuredReview;

  return (
    <>
      <Header />
      <MotionInit />
      <main>
        {frames ? (
          <ScrollSequence
            manifest={frames}
            beats={[
              { at: 0.02, kicker: `${business.address.city}, CT`, title: business.name },
              { at: 0.4, kicker: "Walkways · Steps · Yard care", title: "Every cut, every detail." },
              { at: 0.72, kicker: "From a Google review", title: "“Great work at a fair price.”" },
            ]}
          />
        ) : (
          <Hero />
        )}

        {/* services ribbon */}
        <div className="overflow-hidden border-y border-char/10 bg-grass-light py-4 text-char" aria-hidden>
          <div className="marquee flex w-max gap-10 font-display text-2xl font-extrabold whitespace-nowrap">
            {[...business.services, ...business.services, ...business.services, ...business.services].map((s, i) => (
              <span key={i} className="flex items-center gap-10">
                {s.title} <span className="text-grass">✦</span>
              </span>
            ))}
          </div>
        </div>

        {/* services */}
        <section id="services" className="py-24 sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <div className="flex flex-col justify-between gap-6 lg:flex-row lg:items-end">
              <Heading kicker="Services">
                Hardscape that lasts.
                <br />
                <span className="text-grass">Yard care all year.</span>
              </Heading>
              <p data-reveal className="max-w-sm text-lg text-char/70">
                From a new walkway to the weekly mow and the fall cleanup, it&apos;s one local crew for the whole property.
              </p>
            </div>
            <div className="mt-14 grid gap-4 sm:grid-cols-2 lg:grid-cols-6">
              {business.services.map((s, i) => (
                <article
                  key={s.title}
                  data-reveal={i * 0.07}
                  className={`group rounded-3xl bg-white p-7 shadow-sm ring-1 ring-char/5 transition duration-300 hover:-translate-y-1 hover:shadow-xl ${i < 2 ? "lg:col-span-3" : "lg:col-span-2"}`}
                >
                  <span className={`inline-block rounded-full px-3 py-1 text-xs font-bold tracking-wide uppercase ${tagColor[s.tag]}`}>{s.tag}</span>
                  <h3 className="mt-5 font-display text-2xl font-extrabold">{s.title}</h3>
                  <p className="mt-2 text-char/70">{s.body}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* featured work */}
        <section id="work" className="bg-char py-24 text-stone sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <Heading kicker="Recent work" light>
              Look at the <span className="text-grass-light">cuts.</span>
            </Heading>
            <div className="mt-14 grid gap-6 md:grid-cols-2">
              {business.photos.map((p, i) => (
                <figure key={p.src} data-reveal={i * 0.12} className={`group ${i === 1 ? "md:mt-24" : ""}`}>
                  <div className="overflow-hidden rounded-3xl ring-1 ring-stone/10">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={p.src} alt={p.alt} loading="lazy" className="aspect-[850/815] w-full object-cover transition duration-700 group-hover:scale-105" />
                  </div>
                  <figcaption className="mt-4 flex items-baseline justify-between gap-4">
                    <span className="font-display text-xl font-bold">{i === 0 ? "Curved paver walkway" : "Granite & paver steps"}</span>
                    <span className="text-sm text-stone/50">{i === 0 ? "Charcoal border" : "Built into the slope"}</span>
                  </figcaption>
                </figure>
              ))}
            </div>
            <div data-reveal className="mt-10 grid grid-cols-2 gap-4 md:grid-cols-4">
              {[1, 2, 3, 4].map((n) => (
                <div key={n} className="grid aspect-square place-items-center rounded-2xl bg-char-soft p-3 text-center ring-1 ring-stone/10">
                  <Ph>More job photos {n}</Ph>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* reviews */}
        <section id="reviews" className="pavers relative py-24 sm:py-32">
          <div className="mx-auto max-w-5xl px-4 sm:px-8">
            <div data-reveal className="rounded-[2rem] bg-white p-8 shadow-2xl shadow-char/10 sm:p-14">
              <div className="flex flex-wrap items-center justify-between gap-4">
                <Stars value={r.rating} className="text-grass" />
                <a href={business.googleUrl} target="_blank" rel="noopener" className="text-sm font-semibold text-char/60 hover:text-grass">
                  {business.rating.toFixed(1)} ★ · {business.reviewCount} reviews on Google →
                </a>
              </div>
              <blockquote className="mt-8 font-display text-[clamp(1.6rem,3.6vw,2.6rem)] leading-[1.15] font-bold tracking-tight">
                &ldquo;Great work at a fair price. Recent walkway installed and back steps.{" "}
                <span className="text-grass">Manny &amp; crew worked hard with great attention to cutting and detail.</span> We plan
                to use Manny in he spring for additional landscaping work. Highly recommend&rdquo;
              </blockquote>
              <p className="mt-8 flex items-center gap-3">
                <span className="grid h-11 w-11 place-items-center rounded-full bg-char font-display font-bold text-grass-light">{r.name[0]}</span>
                <span>
                  <b className="block">{r.name}</b>
                  <span className="text-sm text-char/60">Google review · the walkway &amp; steps on this page</span>
                </span>
              </p>
            </div>
            <figure data-reveal className="mx-auto mt-8 max-w-2xl rounded-2xl bg-char px-8 py-6 text-center text-stone">
              <blockquote className="font-display text-xl font-bold">&ldquo;{business.highlightQuote}&rdquo;</blockquote>
              <figcaption className="mt-2 text-sm text-stone/60">Google review</figcaption>
            </figure>
          </div>
        </section>

        {/* about */}
        <section className="py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl gap-12 px-4 sm:px-8 lg:grid-cols-2 lg:items-center">
            <Heading kicker="About">
              Meet {business.ownerName}<span className="text-grass">.</span>
            </Heading>
            <div data-reveal className="space-y-5 text-lg leading-relaxed text-char/75">
              {business.about ? (
                <p>{business.about}</p>
              ) : (
                <p>
                  <Ph>Manny&apos;s story: how he got started, how long he&apos;s been doing this, and what he&apos;s proud of.</Ph>
                </p>
              )}
              <p>
                {business.legalName} is based right here in {business.address.city}. When you call, you talk to {business.ownerName}, and{" "}
                {business.ownerName} and his crew are the ones who show up to do the work.
              </p>
              <p className="text-base text-char/55">Serving {business.serviceArea ?? <Ph>towns served</Ph>}</p>
            </div>
          </div>
        </section>

        {/* contact + location */}
        <section id="contact" className="bg-stone-deep py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl gap-12 px-4 sm:px-8 lg:grid-cols-2">
            <div>
              <Heading kicker="Get a quote">
                Let&apos;s talk about <span className="text-grass">your yard.</span>
              </Heading>
              <a data-reveal href={business.phoneHref} className="mt-8 block font-display text-4xl font-extrabold hover:text-grass sm:text-5xl">
                {business.phone}
              </a>
              <address data-reveal className="mt-6 text-lg not-italic text-char/75">
                {fullAddress}
              </address>
              <div data-reveal className="mt-4 text-char/75">
                {business.hours ? business.hours.map((h) => <p key={h.days}>{h.days}: {h.time}</p>) : <Ph>Business hours</Ph>}
              </div>
              <div data-reveal className="mt-8 h-64 overflow-hidden rounded-3xl ring-1 ring-char/10">
                <iframe title={`Map to ${business.name}`} src={business.mapEmbed} className="h-full w-full border-0" loading="lazy" referrerPolicy="no-referrer-when-downgrade" />
              </div>
            </div>
            <div data-reveal>
              <ContactForm />
            </div>
          </div>
        </section>
      </main>

      <footer className="bg-char py-10 text-stone/60">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 px-4 text-stone sm:px-8 md:flex-row md:items-center md:justify-between">
          <Logo />
          <p className="text-sm text-stone/60">
            {fullAddress} · <a href={business.phoneHref} className="hover:text-stone">{business.phone}</a>
          </p>
          <p className="text-xs text-stone/60">
            © {new Date().getFullYear()} {business.legalName} · Website by <span className="font-semibold text-stone/80">CyberEdge Creations</span>
          </p>
        </div>
      </footer>
    </>
  );
}
