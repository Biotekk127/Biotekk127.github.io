"use client";

import { useState } from "react";
import { business } from "@/lib/business";

const field =
  "w-full border-0 border-b border-cream/20 bg-transparent px-0 py-4 text-lg text-cream placeholder:text-cream/40 transition focus:border-red-bright focus:ring-0 focus:outline-none";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const d = new FormData(e.currentTarget);
    const services = d.getAll("service").join(", ");
    if (business.email) {
      const body = `Name: ${d.get("name")}\nPhone: ${d.get("phone")}\nAddress: ${d.get("address")}\nInterested in: ${services}\n\n${d.get("message")}`;
      window.location.href = `mailto:${business.email}?subject=${encodeURIComponent("Quote request")}&body=${encodeURIComponent(body)}`;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <div className="rounded-[1.75rem] bg-cream/5 p-10 ring-1 ring-cream/10">
        <p className="font-display text-4xl font-semibold tracking-tight">
          Thank you<span className="text-red-bright">.</span>
        </p>
        <p className="mt-3 text-cream/70">
          {business.ownerName} will be in touch soon. Need it sooner? Call{" "}
          <a href={business.phoneHref} className="text-cream underline underline-offset-4">
            {business.phone}
          </a>
          .
        </p>
        {!business.email && <p className="placeholder mt-5 rounded px-3 py-2">[PLACEHOLDER] Form not yet connected to the owner&apos;s email.</p>}
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="grid gap-x-8 sm:grid-cols-2">
      <input required name="name" aria-label="Name" autoComplete="name" placeholder="Name" className={field} />
      <input required name="phone" aria-label="Phone" type="tel" autoComplete="tel" placeholder="Phone" className={field} />
      <input name="address" aria-label="Property address" autoComplete="street-address" placeholder="Property address" className={`${field} sm:col-span-2`} />
      <fieldset className="pt-8 sm:col-span-2">
        <legend className="idx mb-4 text-cream/50">I&apos;m interested in</legend>
        <div className="flex flex-wrap gap-2">
          {business.services.map((s) => (
            <label key={s.title} className="cursor-pointer">
              <input type="checkbox" name="service" value={s.title} className="peer sr-only" />
              <span className="inline-block rounded-full px-4 py-2 text-sm text-cream/80 ring-1 ring-cream/20 transition peer-checked:bg-cream peer-checked:text-navy peer-checked:ring-cream peer-focus-visible:ring-2 peer-focus-visible:ring-red-bright hover:ring-cream/50">
                {s.title}
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <textarea name="message" aria-label="Message" rows={3} placeholder="Tell us about the project" className={`${field} mt-4 resize-none sm:col-span-2`} />
      <div className="mt-10 sm:col-span-2">
        <button data-magnetic className="inline-flex items-center gap-3 rounded-full bg-red py-2 pr-2 pl-7 text-lg font-medium text-cream transition-colors hover:bg-red-bright">
          Send request
          <span className="grid h-11 w-11 place-items-center rounded-full bg-cream text-navy" aria-hidden>
            →
          </span>
        </button>
      </div>
    </form>
  );
}
