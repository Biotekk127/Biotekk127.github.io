import fs from "node:fs";
import path from "node:path";
import { business, fullAddress, PLACEHOLDER } from "@/lib/business";
import { Header, Logo } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { ScrollSequence, type FrameManifest } from "@/components/ScrollSequence";
import { MotionInit } from "@/components/MotionInit";
import { ContactForm } from "@/components/ContactForm";
import { Stars } from "@/components/Stars";

/** If the client's video has been turned into frames, use the cinematic scroll hero. */
function readFrames(): FrameManifest | null {
  const file = path.join(process.cwd(), "public/frames/manifest.json");
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : null;
}

function Ph({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <span className={`placeholder rounded px-2 py-0.5 ${className}`}>{PLACEHOLDER} {children}</span>;
}

const icons: Record<string, React.ReactNode> = {
  roof: <path d="M4 26 L24 8 L44 26 M10 21 V40 H38 V21" />,
  repair: <path d="M8 40 L26 22 M22 10 a8 8 0 1 0 12 10 l6 6 -4 4 -6 -6 a8 8 0 0 1 -8 -14 z" />,
  siding: <path d="M8 12 H40 V40 H8 Z M8 19 H40 M8 26 H40 M8 33 H40" />,
  reno: <path d="M10 40 V18 L24 8 L38 18 V40 Z M19 40 V28 H29 V40 M30 6 L34 10" />,
};

function SectionTitle({ kicker, title, dark = false }: { kicker: string; title: React.ReactNode; dark?: boolean }) {
  return (
    <div data-reveal className="mb-12 max-w-3xl">
      <p className="mb-3 text-sm font-bold tracking-[0.25em] text-copper uppercase">{kicker}</p>
      <h2 className={`font-display text-[clamp(2rem,5vw,3.75rem)] leading-[0.95] font-black tracking-tight uppercase ${dark ? "text-bone" : "text-slate-ink"}`}>
        {title}
      </h2>
    </div>
  );
}

export default function Page() {
  const frames = readFrames();
  const ratingText = business.rating ? business.rating.toFixed(1) : null;

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
              { at: 0.38, kicker: "Roofing · Siding · Renovations", title: "Built to weather New England." },
              {
                at: 0.72,
                kicker: "Trusted by your neighbors",
                title: ratingText ? `Rated ${ratingText}★ by ${business.reviewCount} customers` : "Rated ★ on Google",
              },
            ]}
          />
        ) : (
          <Hero />
        )}

        {/* trust strip */}
        <section className="border-y border-slate-ink/10 bg-bone">
          <div className="mx-auto grid max-w-6xl grid-cols-2 gap-6 px-4 py-8 text-center sm:px-8 md:grid-cols-4">
            {[
              ["Local", `Based in ${business.address.city}`],
              ["Free", "Estimates"],
              [ratingText ? `${ratingText}★` : "—", ratingText ? "Google rating" : <Ph key="r">rating</Ph>],
              [business.yearsInBusiness ? `${business.yearsInBusiness}+` : "—", business.yearsInBusiness ? "Years in business" : <Ph key="y">years</Ph>],
            ].map(([big, small], i) => (
              <div key={i} data-reveal={i * 0.08}>
                <p className="font-display text-3xl font-black text-slate-ink uppercase sm:text-4xl">{big}</p>
                <p className="mt-1 text-sm text-slate-ink/70">{small}</p>
              </div>
            ))}
          </div>
        </section>

        {/* about */}
        <section id="about" className="relative overflow-hidden bg-bone py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl items-center gap-14 px-4 sm:px-8 lg:grid-cols-2">
            <div>
              <SectionTitle kicker="About us" title={<>Your roof is the first line of defense.</>} />
              <div data-reveal className="space-y-5 text-lg leading-relaxed text-slate-ink/80">
                {business.about ? (
                  <p>{business.about}</p>
                ) : (
                  <p>
                    <Ph>Owner&apos;s story — how {business.name} started, who runs it, and what they care about.</Ph>
                  </p>
                )}
                <p>
                  From full roof replacements to siding and renovation projects, {business.name} works on homes across{" "}
                  {business.serviceArea ?? <Ph>service area towns</Ph>}. Every project starts with an honest look at your
                  home and a clear estimate.
                </p>
              </div>
            </div>
            <div data-reveal className="relative aspect-[4/5] overflow-hidden rounded-2xl bg-slate-deep shadow-2xl shadow-slate-ink/30">
              <div data-parallax="-12" className="shingles absolute -inset-10 bg-[linear-gradient(160deg,#1e3246,#0c1622)]" />
              {business.photos[0] ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={business.photos[0].src} alt={business.photos[0].alt} className="absolute inset-0 h-full w-full object-cover" />
              ) : (
                <div className="absolute inset-0 grid place-items-center p-8 text-center">
                  <Ph>Crew or project photo from Google profile</Ph>
                </div>
              )}
              <div className="absolute bottom-0 left-0 rounded-tr-2xl bg-copper px-6 py-4 font-display font-black text-slate-ink uppercase">
                Locally owned · {business.address.city}
              </div>
            </div>
          </div>
        </section>

        {/* services */}
        <section id="services" className="grain relative bg-slate-ink py-24 text-bone sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <SectionTitle dark kicker="What we do" title="Roofing, siding & renovations." />
            <div className="grid gap-5 sm:grid-cols-2">
              {business.services.map((s, i) => (
                <article
                  key={s.title}
                  data-reveal={i * 0.08}
                  className="group relative overflow-hidden rounded-xl border border-bone/10 bg-slate-deep p-8 transition duration-300 hover:-translate-y-1 hover:border-copper/60"
                >
                  <svg viewBox="0 0 48 48" className="mb-6 h-12 w-12 fill-none stroke-copper" strokeWidth="3" strokeLinejoin="round" aria-hidden>
                    {icons[s.icon]}
                  </svg>
                  <h3 className="font-display text-2xl font-black uppercase">{s.title}</h3>
                  <p className="mt-3 text-bone/75">{s.body}</p>
                  <span className="absolute -right-6 -bottom-8 font-display text-[7rem] font-black text-bone/[0.03] transition group-hover:text-copper/10">
                    0{i + 1}
                  </span>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* reviews */}
        <section id="reviews" className="bg-bone py-24 sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <div className="mb-12 flex flex-col justify-between gap-8 lg:flex-row lg:items-end">
              <SectionTitle kicker="Google reviews" title="What homeowners say." />
              <div data-reveal className="flex items-center gap-5 rounded-xl bg-white p-6 shadow-xl shadow-slate-ink/5">
                <p className="font-display text-6xl font-black">{ratingText ?? <Ph className="text-base">X.X</Ph>}</p>
                <div>
                  <Stars value={business.rating ?? 5} className="text-copper" />
                  <p className="mt-1 text-sm text-slate-ink/70">
                    {business.reviewCount ? `${business.reviewCount} reviews on Google` : <Ph>review count</Ph>}
                  </p>
                </div>
              </div>
            </div>

            <div className="grid gap-5 md:grid-cols-3">
              {(business.reviews.length ? business.reviews : [null, null, null]).map((r, i) => (
                <figure key={i} data-reveal={i * 0.1} className="flex flex-col rounded-xl bg-white p-7 shadow-xl shadow-slate-ink/5">
                  <Stars value={r?.rating ?? 5} className="text-copper" />
                  <blockquote className="mt-4 flex-1 text-slate-ink/85">
                    {r ? <>&ldquo;{r.text}&rdquo;</> : <Ph>Paste a real Google review here, word for word.</Ph>}
                  </blockquote>
                  <figcaption className="mt-6 flex items-center gap-3 border-t border-slate-ink/10 pt-4">
                    <span className="grid h-10 w-10 place-items-center rounded-full bg-slate-ink font-display font-black text-copper">
                      {r ? r.name[0] : "?"}
                    </span>
                    <span>
                      <b className="block">{r ? r.name : <Ph>Reviewer first name</Ph>}</b>
                      <span className="text-sm text-slate-ink/60">Google review{r?.when ? ` · ${r.when}` : ""}</span>
                    </span>
                  </figcaption>
                </figure>
              ))}
            </div>

            <a data-reveal href={business.googleUrl} target="_blank" rel="noopener" className="mt-10 inline-flex items-center gap-2 font-display font-extrabold tracking-wide text-slate-ink uppercase underline decoration-copper decoration-4 underline-offset-8 hover:text-copper">
              See us on Google →
            </a>
          </div>
        </section>

        {/* gallery */}
        <section id="work" className="bg-slate-deep py-24 text-bone sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <SectionTitle dark kicker="Recent work" title="Roofs we're proud of." />
            <div className="grid auto-rows-[220px] grid-cols-2 gap-4 md:grid-cols-4">
              {(business.photos.length ? business.photos : Array.from({ length: 6 }, () => null)).map((p, i) => (
                <div
                  key={i}
                  data-reveal={(i % 4) * 0.06}
                  className={`relative overflow-hidden rounded-xl bg-slate-mid ${i === 0 ? "col-span-2 row-span-2" : ""} ${i === 3 || i === 4 ? "md:col-span-2" : ""} ${i === 5 ? "col-span-2" : ""}`}
                >
                  {p ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.src} alt={p.alt} loading="lazy" className="h-full w-full object-cover transition duration-700 hover:scale-105" />
                  ) : (
                    <div className="shingles grid h-full place-items-center bg-[linear-gradient(150deg,#1e3246,#13212f)] p-4 text-center text-sm">
                      <Ph>Project photo {i + 1}</Ph>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* location */}
        <section id="location" className="bg-bone py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl gap-10 px-4 sm:px-8 lg:grid-cols-5">
            <div className="lg:col-span-2">
              <SectionTitle kicker="Visit or call" title="Hours & location." />
              <address data-reveal className="text-lg not-italic">
                <b className="block font-display text-xl uppercase">{business.name}</b>
                {fullAddress}
                <a href={business.phoneHref} className="mt-2 block font-semibold text-copper hover:underline">
                  {business.phone}
                </a>
              </address>
              <dl data-reveal className="mt-8 divide-y divide-slate-ink/10 border-y border-slate-ink/10">
                {business.hours ? (
                  business.hours.map((h) => (
                    <div key={h.days} className="flex justify-between py-3">
                      <dt className="font-semibold">{h.days}</dt>
                      <dd className="text-slate-ink/70">{h.time}</dd>
                    </div>
                  ))
                ) : (
                  <div className="py-3">
                    <Ph>Business hours from Google profile</Ph>
                  </div>
                )}
              </dl>
              <a data-reveal href={business.directionsUrl} target="_blank" rel="noopener" className="mt-8 inline-block rounded-md bg-slate-ink px-6 py-3.5 font-display font-extrabold tracking-wide text-bone uppercase hover:bg-slate-mid">
                Get directions
              </a>
            </div>
            <div data-reveal className="min-h-[380px] overflow-hidden rounded-2xl shadow-2xl shadow-slate-ink/20 lg:col-span-3">
              <iframe
                title={`Map to ${business.name}`}
                src={`https://maps.google.com/maps?q=${encodeURIComponent(`${business.name}, ${fullAddress}`)}&z=14&output=embed`}
                className="h-full min-h-[380px] w-full border-0 grayscale-[30%]"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
              />
            </div>
          </div>
        </section>

        {/* contact */}
        <section id="contact" className="grain relative overflow-hidden bg-slate-ink py-24 text-bone sm:py-32">
          <div className="absolute -top-40 -right-40 h-[32rem] w-[32rem] rounded-full bg-copper/20 blur-3xl" aria-hidden />
          <div className="relative mx-auto grid max-w-6xl gap-14 px-4 sm:px-8 lg:grid-cols-2">
            <div>
              <SectionTitle dark kicker="Free estimate" title={<>Let&apos;s look at your roof.</>} />
              <p data-reveal className="max-w-md text-lg text-bone/75">
                Tell us what&apos;s going on: a leak, storm damage, an aging roof or a siding project. We&apos;ll get back to you with
                next steps and an honest estimate.
              </p>
              <a data-reveal href={business.phoneHref} className="mt-8 inline-block font-display text-4xl font-black text-copper hover:text-copper-light sm:text-5xl">
                {business.phone}
              </a>
            </div>
            <div data-reveal>
              <ContactForm />
            </div>
          </div>
        </section>
      </main>

      <footer className="bg-[#070d14] py-12 text-bone/60">
        <div className="mx-auto flex max-w-6xl flex-col gap-8 px-4 sm:px-8 md:flex-row md:items-center md:justify-between">
          <Logo className="text-bone" />
          <p className="text-sm">
            {fullAddress} · <a href={business.phoneHref} className="hover:text-bone">{business.phone}</a>
          </p>
          <p className="text-xs">
            © {new Date().getFullYear()} {business.name} · Website by{" "}
            <span className="font-semibold text-bone/80">CyberEdge Creations</span>
          </p>
        </div>
      </footer>
    </>
  );
}
