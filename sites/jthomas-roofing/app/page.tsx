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

function Kicker({ children, light = false }: { children: React.ReactNode; light?: boolean }) {
  return (
    <p data-reveal className={`text-sm font-semibold tracking-[0.22em] uppercase ${light ? "text-brass" : "text-brick"}`}>
      {children}
    </p>
  );
}

export default function Page() {
  const frames = readFrames();
  const review = business.reviews[0];

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
              { at: 0.4, kicker: "Roof replacement · Roof repair", title: "Top-notch roofs for homes old & new." },
              { at: 0.72, kicker: "5.0 on Google", title: "“I would call them again!”" },
            ]}
          />
        ) : (
          <Hero />
        )}

        {/* trust strip */}
        <section className="bg-forest text-paper">
          <div className="mx-auto grid max-w-6xl grid-cols-1 divide-y divide-paper/15 px-4 sm:grid-cols-3 sm:divide-x sm:divide-y-0 sm:px-8">
            {[
              ["5.0 ★", "Rated on Google"],
              ["Local", `${business.address.city}, Connecticut`],
              ["Old homes", "Welcome, including a house built in 1904"],
            ].map(([a, b], i) => (
              <div key={a} data-reveal={i * 0.08} className="py-7 text-center">
                <p className="font-serif text-3xl font-semibold text-brass">{a}</p>
                <p className="mt-1 text-sm text-paper/75">{b}</p>
              </div>
            ))}
          </div>
        </section>

        {/* about */}
        <section className="py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl gap-14 px-4 sm:px-8 lg:grid-cols-2 lg:items-center">
            <div className="relative order-2 lg:order-1">
              <div data-reveal className="relative aspect-[4/3] overflow-hidden rounded-[2rem] bg-paper-deep ring-1 ring-forest/10">
                {business.photos[0] ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={business.photos[0].src} alt={business.photos[0].alt} className="h-full w-full object-cover" />
                ) : (
                  <div className="drafting grid h-full place-items-center p-8 text-center">
                    <Ph>Photo of a finished roof or the crew</Ph>
                  </div>
                )}
              </div>
              <div data-reveal="0.15" data-parallax="-20" className="absolute -right-3 -bottom-8 rounded-2xl bg-brick px-6 py-5 text-paper shadow-xl sm:-right-8">
                <p className="font-serif text-4xl leading-none font-semibold">1904</p>
                <p className="mt-1 max-w-[10rem] text-xs text-paper/85">The year a customer&apos;s house was built. They still called it top notch.</p>
              </div>
            </div>
            <div className="order-1 lg:order-2">
              <Kicker>About</Kicker>
              <h2 data-reveal className="mt-4 font-serif text-[clamp(2.2rem,5vw,3.6rem)] leading-[1.05] font-semibold text-forest">
                Every house is different. <em className="font-normal text-brick">Older ones especially.</em>
              </h2>
              <div data-reveal className="mt-6 space-y-5 text-lg leading-relaxed text-ink/80">
                {business.about ? (
                  <p>{business.about}</p>
                ) : (
                  <p>
                    <Ph>Owner&apos;s name and story: how {business.name} got started and what they&apos;re known for.</Ph>
                  </p>
                )}
                <p>
                  A century-old roof hides surprises: uneven rafters, layers of old shingles and flashing that was never
                  done right. {business.name} takes the time to do the job properly, whether your house went up in 1904 or
                  2004.
                </p>
                <p className="text-base text-ink/60">
                  Serving {business.serviceArea ?? <Ph>towns served</Ph>}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* services */}
        <section id="services" className="border-y border-forest/15 bg-paper-deep py-24 sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <Kicker>Services</Kicker>
            <h2 data-reveal className="mt-4 max-w-2xl font-serif text-[clamp(2.2rem,5vw,3.6rem)] leading-[1.05] font-semibold text-forest">
              What we do, and how we do it.
            </h2>
            <div className="mt-14 grid gap-px overflow-hidden rounded-3xl bg-forest/15 md:grid-cols-3">
              {business.services.map((s, i) => (
                <article key={s.title} data-reveal={i * 0.1} className="group bg-paper p-8 transition hover:bg-white sm:p-10">
                  <p className="font-serif text-5xl text-brass italic">0{i + 1}</p>
                  <h3 className="mt-6 font-serif text-2xl font-semibold text-forest">{s.title}</h3>
                  <p className="mt-3 leading-relaxed text-ink/75">{s.body}</p>
                  <span className="mt-6 block h-0.5 w-10 bg-brick transition-all duration-500 group-hover:w-24" />
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* the review */}
        <section id="review" className="relative overflow-hidden py-28 sm:py-40">
          <span className="pointer-events-none absolute -top-24 left-1/2 -translate-x-1/2 font-serif text-[28rem] leading-none text-brass/15 select-none" aria-hidden>
            &ldquo;
          </span>
          <div className="relative mx-auto max-w-4xl px-4 text-center sm:px-8">
            <Kicker>From a Google review</Kicker>
            <div data-reveal className="mt-6 flex justify-center">
              <Stars value={review.rating} className="text-brass" />
            </div>
            <blockquote data-reveal className="mt-8 font-serif text-[clamp(1.9rem,4.6vw,3.4rem)] leading-[1.2] text-forest">
              &ldquo;We have a house built in <em className="text-brick">1904</em> and they did a{" "}
              <em className="text-brick">top notch</em> job. I would call them again!&rdquo;
            </blockquote>
            <p data-reveal className="mt-8 text-ink/70">
              <b className="text-ink">{review.name}</b> · Google review · {business.rating.toFixed(1)} ★ rating
            </p>
            <div data-reveal className="rule mx-auto mt-14 max-w-md text-forest">
              <a href={business.googleUrl} target="_blank" rel="noopener" className="font-semibold whitespace-nowrap text-forest hover:text-brick">
                Worked with us? Leave a review →
              </a>
            </div>
          </div>
        </section>

        {/* gallery */}
        <section id="work" className="bg-forest py-24 text-paper sm:py-32">
          <div className="mx-auto max-w-6xl px-4 sm:px-8">
            <Kicker light>Recent work</Kicker>
            <h2 data-reveal className="mt-4 font-serif text-[clamp(2.2rem,5vw,3.6rem)] leading-[1.05] font-semibold">
              Roofs around <em className="font-normal text-brass">Windham County.</em>
            </h2>
            <div className="mt-14 grid auto-rows-[160px] grid-cols-2 gap-4 sm:auto-rows-[230px] md:grid-cols-3">
              {(business.photos.length ? business.photos : Array.from({ length: 5 }, () => null)).map((p, i) => (
                <div key={i} data-reveal={(i % 3) * 0.08} className={`overflow-hidden rounded-2xl bg-forest-light/40 ring-1 ring-paper/10 ${i === 0 ? "row-span-2" : ""}`}>
                  {p ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.src} alt={p.alt} loading="lazy" className="h-full w-full object-cover transition duration-700 hover:scale-105" />
                  ) : (
                    <div className="grid h-full place-items-center p-4 text-center">
                      <Ph>Project photo {i + 1}</Ph>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* location */}
        <section id="location" className="py-24 sm:py-32">
          <div className="mx-auto grid max-w-6xl gap-12 px-4 sm:px-8 lg:grid-cols-[1fr_1.4fr]">
            <div>
              <Kicker>Visit or call</Kicker>
              <h2 data-reveal className="mt-4 font-serif text-[clamp(2.2rem,5vw,3.6rem)] leading-[1.05] font-semibold text-forest">
                Find us in Willimantic.
              </h2>
              <address data-reveal className="mt-8 text-lg leading-relaxed not-italic">
                <b className="font-serif text-xl text-forest">{business.name}</b>
                <br />
                {fullAddress}
                <br />
                <a href={business.phoneHref} className="font-semibold text-brick hover:underline">
                  {business.phone}
                </a>
              </address>
              <div data-reveal className="mt-8 rounded-2xl border border-forest/15 bg-paper-deep p-6">
                <p className="font-serif text-lg font-semibold text-forest">Hours</p>
                {business.hours ? (
                  <dl className="mt-3 space-y-1">
                    {business.hours.map((h) => (
                      <div key={h.days} className="flex justify-between">
                        <dt>{h.days}</dt>
                        <dd className="text-ink/70">{h.time}</dd>
                      </div>
                    ))}
                  </dl>
                ) : (
                  <p className="mt-3">
                    <Ph>Business hours</Ph>
                  </p>
                )}
              </div>
              <a data-reveal href={business.directionsUrl} target="_blank" rel="noopener" className="mt-8 inline-block rounded-full bg-forest px-7 py-3.5 font-semibold text-paper hover:bg-forest-light">
                Get directions
              </a>
            </div>
            <div data-reveal className="min-h-[380px] overflow-hidden rounded-[2rem] ring-1 ring-forest/15">
              <iframe title={`Map to ${business.name}`} src={business.mapEmbed} className="h-full min-h-[380px] w-full border-0 sepia-[25%]" loading="lazy" referrerPolicy="no-referrer-when-downgrade" />
            </div>
          </div>
        </section>

        {/* contact */}
        <section id="contact" className="grain relative overflow-hidden bg-ink py-24 text-paper sm:py-32">
          <div className="relative mx-auto grid max-w-6xl gap-14 px-4 sm:px-8 lg:grid-cols-2">
            <div>
              <Kicker light>Get a quote</Kicker>
              <h2 data-reveal className="mt-4 font-serif text-[clamp(2.4rem,5.5vw,4rem)] leading-[1.02] font-semibold">
                Let&apos;s take a look <em className="font-normal text-brass">at your roof.</em>
              </h2>
              <p data-reveal className="mt-6 max-w-md text-lg text-paper/75">
                Tell us a little about the house and what&apos;s going on up top, and we&apos;ll get back to you.
              </p>
              <a data-reveal href={business.phoneHref} className="mt-8 inline-block font-serif text-4xl text-brass hover:text-paper sm:text-5xl">
                {business.phone}
              </a>
            </div>
            <div data-reveal>
              <ContactForm />
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-paper/10 bg-ink py-10 text-paper/60">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 px-4 sm:px-8 md:flex-row md:items-center md:justify-between">
          <Logo light />
          <p className="text-sm">
            {fullAddress} · <a href={business.phoneHref} className="hover:text-paper">{business.phone}</a>
          </p>
          <p className="text-xs">
            © {new Date().getFullYear()} {business.name} · Website by <span className="font-semibold text-paper/80">CyberEdge Creations</span>
          </p>
        </div>
      </footer>
    </>
  );
}
