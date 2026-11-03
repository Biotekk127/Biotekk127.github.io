import fs from "node:fs";
import path from "node:path";
import { business, fullAddress, PLACEHOLDER } from "@/lib/business";
import { Header, Wordmark } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { ScrollSequence, type FrameManifest } from "@/components/ScrollSequence";
import { MotionInit } from "@/components/MotionInit";
import { ContactForm } from "@/components/ContactForm";

function readFrames(): FrameManifest | null {
  const file = path.join(process.cwd(), "public/frames/manifest.json");
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : null;
}

function Ph({ children }: { children: React.ReactNode }) {
  return <span className="placeholder rounded px-2 py-0.5">{PLACEHOLDER} {children}</span>;
}

/** Section header: index label on a hairline, then a big masked-reveal title. */
function SectionHead({ n, label, children, light = false }: { n: string; label: string; children: React.ReactNode; light?: boolean }) {
  return (
    <div>
      <div data-reveal className={`flex items-center justify-between border-b pb-5 ${light ? "border-cream/15 text-cream/55" : "border-navy/15 text-navy/55"}`}>
        <span className="idx">({n}) {label}</span>
        <span className="idx hidden sm:block">{business.name}</span>
      </div>
      <h2 data-split className="mt-10 max-w-5xl font-display text-[clamp(2.6rem,6.5vw,6rem)] leading-[0.95] font-semibold tracking-[-0.045em]">
        {children}
      </h2>
    </div>
  );
}

const seasons: Record<string, string> = { Hardscape: "Year-round", Spring: "Spring", Summer: "Summer", Fall: "Fall" };

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

        {/* statement */}
        <section className="py-28 sm:py-40">
          <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
            <div data-reveal className="flex items-center justify-between border-b border-navy/15 pb-5 text-navy/55">
              <span className="idx">(02) The approach</span>
              <span className="idx hidden sm:block">Based in {business.address.city}</span>
            </div>
            <p data-words className="mt-14 max-w-6xl font-display text-[clamp(1.9rem,4.4vw,4rem)] leading-[1.08] font-medium tracking-[-0.035em]">
              Good hardscape is quiet. The borders run true, the cuts are clean, and the steps feel solid underfoot. That&apos;s
              the standard Manny and his crew hold on every walkway, every set of steps and every yard they look after.
            </p>
          </div>
        </section>

        {/* services */}
        <section id="services" className="pb-28 sm:pb-40">
          <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
            <SectionHead n="03" label="Services">
              Built to last.
              <br />
              <em className="font-serif font-normal tracking-[-0.02em] text-red italic">Kept sharp all year.</em>
            </SectionHead>
            <ul className="mt-16 border-t border-navy/15">
              {business.services.map((s, i) => (
                <li key={s.title} data-reveal={i * 0.05} className="row-fill group border-b border-navy/15 transition-colors duration-500 hover:text-cream">
                  <a href="#contact" className="grid grid-cols-12 items-center gap-4 px-2 py-8 sm:px-6 sm:py-10">
                    <span className="idx col-span-2 text-navy/45 transition-colors group-hover:text-cream/50 sm:col-span-1">0{i + 1}</span>
                    <span className="col-span-10 font-display text-[clamp(1.7rem,3.6vw,3.25rem)] leading-none font-semibold tracking-[-0.04em] sm:col-span-5">
                      {s.title}
                    </span>
                    <span className="col-span-12 text-navy/65 transition-colors group-hover:text-cream/70 sm:col-span-4">{s.body}</span>
                    <span className="col-span-12 flex items-center justify-between sm:col-span-2 sm:justify-end sm:gap-5">
                      <span className="idx rounded-full px-3 py-1.5 ring-1 ring-current/25">{seasons[s.tag]}</span>
                      <span className="grid h-11 w-11 -rotate-45 place-items-center rounded-full bg-navy text-cream transition duration-500 group-hover:rotate-0 group-hover:bg-red" aria-hidden>
                        →
                      </span>
                    </span>
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* work */}
        <section id="work" className="grain relative bg-navy py-28 text-cream sm:py-40">
          <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
            <SectionHead n="04" label="Selected work" light>
              Look closely at <em className="font-serif font-normal tracking-[-0.02em] text-red-bright italic">the cuts.</em>
            </SectionHead>
            <div className="mt-16 grid gap-6 lg:grid-cols-12 lg:gap-8">
              {business.photos.map((p, i) => (
                <figure key={p.src} className={i === 0 ? "lg:col-span-7" : "lg:col-span-5 lg:mt-40"}>
                  <div data-clip className="overflow-hidden rounded-[1.5rem]">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={p.src} alt={p.alt} loading="lazy" className={`w-full object-cover ${i === 0 ? "aspect-[4/5] lg:aspect-[7/8]" : "aspect-[4/5]"}`} />
                  </div>
                  <figcaption data-reveal className="mt-5 flex items-baseline justify-between gap-4 border-t border-cream/15 pt-4">
                    <span className="font-serif text-2xl italic">{i === 0 ? "Curved paver walkway" : "Granite & paver steps"}</span>
                    <span className="idx text-cream/50">{i === 0 ? "Charcoal border" : "Built into the slope"}</span>
                  </figcaption>
                </figure>
              ))}
            </div>
            <p data-reveal className="mt-14 text-center text-cream/60">
              <Ph>Add 4–6 more of Manny&apos;s job photos for a full gallery</Ph>
            </p>
          </div>
        </section>

        {/* review */}
        <section id="reviews" className="bg-beige py-28 sm:py-40">
          <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
            <div data-reveal className="flex items-center justify-between border-b border-navy/15 pb-5 text-navy/55">
              <span className="idx">(05) Google reviews</span>
              <a href={business.googleUrl} target="_blank" rel="noopener" className="idx hover:text-red">
                {business.rating.toFixed(1)} ★ · {business.reviewCount} reviews ↗
              </a>
            </div>
            <div className="mt-16 grid gap-12 lg:grid-cols-12">
              <span className="font-serif text-[10rem] leading-[0.6] text-red lg:col-span-2" aria-hidden>
                &ldquo;
              </span>
              <figure className="lg:col-span-10">
                <blockquote data-split className="font-display text-[clamp(1.8rem,3.8vw,3.5rem)] leading-[1.1] font-medium tracking-[-0.035em]">
                  Great work at a fair price. Recent walkway installed and back steps.{" "}
                  <em className="font-serif font-normal tracking-[-0.01em] text-red italic">
                    Manny &amp; crew worked hard with great attention to cutting and detail.
                  </em>{" "}
                  We plan to use Manny in he spring for additional landscaping work. Highly recommend
                </blockquote>
                <figcaption data-reveal className="mt-10 flex flex-wrap items-center gap-x-8 gap-y-3 border-t border-navy/15 pt-6">
                  <span className="font-medium">{r.name}</span>
                  <span className="text-navy/55">Google review · the walkway and steps shown above</span>
                </figcaption>
                <p data-reveal className="mt-12 max-w-xl font-serif text-2xl text-navy/80 italic">
                  &ldquo;{business.highlightQuote}&rdquo; <span className="font-sans text-sm text-navy/50 not-italic">Google review</span>
                </p>
              </figure>
            </div>
          </div>
        </section>

        {/* about */}
        <section id="about" className="py-28 sm:py-40">
          <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
            <SectionHead n="06" label="About">
              One crew. <em className="font-serif font-normal tracking-[-0.02em] text-red italic">One standard.</em>
            </SectionHead>
            <div className="mt-16 grid gap-12 lg:grid-cols-12">
              <div data-reveal className="space-y-6 text-lg leading-relaxed text-navy/75 lg:col-span-6 lg:col-start-7">
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
              </div>
              <dl className="grid grid-cols-2 gap-px overflow-hidden rounded-[1.5rem] bg-navy/15 lg:col-span-5 lg:row-start-1">
                {[
                  [String(business.reviewCount), "Google reviews"],
                  ["5", "Services, one crew"],
                  ["Spring–Fall", "Yard care seasons"],
                  [business.address.city, "Home base"],
                ].map(([a, b], i) => (
                  <div key={b} data-reveal={i * 0.06} className="bg-cream p-6 sm:p-8">
                    <dt className="font-display text-[clamp(1.8rem,3.2vw,3rem)] leading-none font-semibold tracking-[-0.04em]">{a}</dt>
                    <dd className="idx mt-3 text-navy/55">{b}</dd>
                  </div>
                ))}
              </dl>
            </div>
          </div>
        </section>

        {/* contact */}
        <section id="contact" className="grain relative overflow-hidden bg-navy py-28 text-cream sm:py-40">
          <div className="pointer-events-none absolute bottom-0 left-0 h-[36rem] w-[36rem] -translate-x-1/3 translate-y-1/3 rounded-full bg-red/20 blur-[120px]" aria-hidden />
          <div className="relative mx-auto max-w-[88rem] px-4 sm:px-8">
            <SectionHead n="07" label="Get a quote" light>
              Let&apos;s build something <em className="font-serif font-normal tracking-[-0.02em] text-red-bright italic">solid.</em>
            </SectionHead>
            <div className="mt-16 grid gap-16 lg:grid-cols-12">
              <div className="space-y-10 lg:col-span-5">
                <a data-reveal href={business.phoneHref} className="block font-display text-[clamp(2rem,4vw,3.5rem)] leading-none font-semibold tracking-[-0.04em] transition hover:text-red-bright">
                  {business.phone}
                </a>
                <dl data-reveal className="grid grid-cols-2 gap-6 border-t border-cream/15 pt-6 text-cream/70">
                  <div>
                    <dt className="idx text-cream/45">Address</dt>
                    <dd className="mt-2">
                      {business.address.street}
                      <br />
                      {business.address.city}, {business.address.region} {business.address.postal}
                    </dd>
                  </div>
                  <div>
                    <dt className="idx text-cream/45">Hours</dt>
                    <dd className="mt-2">{business.hours ? business.hours.map((h) => <span key={h.days} className="block">{h.days}: {h.time}</span>) : <Ph>Hours</Ph>}</dd>
                  </div>
                </dl>
                <div data-reveal className="aspect-[4/3] overflow-hidden rounded-[1.5rem] ring-1 ring-cream/10">
                  <iframe title={`Map to ${business.name}`} src={business.mapEmbed} className="h-full w-full border-0 opacity-90 grayscale invert-[0.92] hue-rotate-180" loading="lazy" referrerPolicy="no-referrer-when-downgrade" />
                </div>
              </div>
              <div data-reveal className="lg:col-span-6 lg:col-start-7">
                <ContactForm />
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="overflow-hidden bg-navy pt-10 pb-8 text-cream">
        <div className="mx-auto max-w-[88rem] px-4 sm:px-8">
          <div className="flex flex-col gap-6 border-t border-cream/15 pt-8 text-sm text-cream/60 md:flex-row md:items-center md:justify-between">
            <Wordmark className="text-cream" />
            <span>
              {fullAddress} · <a href={business.phoneHref} className="hover:text-cream">{business.phone}</a>
            </span>
            <span className="text-xs">
              © {new Date().getFullYear()} {business.legalName} · Website by <span className="text-cream/85">CyberEdge Creations</span>
            </span>
          </div>
          <p className="outline-type mt-10 font-display text-[23vw] leading-[0.8] font-semibold tracking-[-0.06em] select-none sm:text-[21vw]" aria-hidden>
            Manny&apos;s
          </p>
        </div>
      </footer>
    </>
  );
}
