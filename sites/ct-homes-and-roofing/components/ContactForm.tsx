"use client";

import { useState } from "react";
import { business } from "@/lib/business";

const field =
  "w-full rounded-md border border-bone/15 bg-bone/5 px-4 py-3 text-bone placeholder:text-bone/40 focus:border-copper focus:outline-none focus:ring-2 focus:ring-copper/40";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(e.currentTarget)) as Record<string, string>;
    if (business.email) {
      const body = `Name: ${data.name}\nPhone: ${data.phone}\nAddress: ${data.address}\nService: ${data.service}\n\n${data.message}`;
      window.location.href = `mailto:${business.email}?subject=${encodeURIComponent("Quote request")}&body=${encodeURIComponent(body)}`;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <div className="rounded-xl border border-copper/40 bg-copper/10 p-8 text-bone">
        <p className="font-display text-2xl font-black uppercase">Thanks, we got it.</p>
        <p className="mt-2 text-bone/80">
          We&apos;ll reach out soon. Need help faster? Call{" "}
          <a className="font-semibold text-copper-light underline" href={business.phoneHref}>
            {business.phone}
          </a>
          .
        </p>
        {!business.email && <p className="placeholder mt-4 rounded px-3 py-2 text-sm">[PLACEHOLDER] Form not yet connected to the owner&apos;s email.</p>}
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
      <label className="sm:col-span-1">
        <span className="sr-only">Name</span>
        <input required name="name" autoComplete="name" placeholder="Your name" className={field} />
      </label>
      <label>
        <span className="sr-only">Phone</span>
        <input required name="phone" type="tel" autoComplete="tel" placeholder="Phone" className={field} />
      </label>
      <label className="sm:col-span-2">
        <span className="sr-only">Property address</span>
        <input name="address" autoComplete="street-address" placeholder="Property address" className={field} />
      </label>
      <label className="sm:col-span-2">
        <span className="sr-only">Service</span>
        <select name="service" className={field} defaultValue="">
          <option value="" disabled>
            What do you need?
          </option>
          {business.services.map((s) => (
            <option key={s.title} className="text-slate-ink">
              {s.title}
            </option>
          ))}
          <option className="text-slate-ink">Not sure — need an inspection</option>
        </select>
      </label>
      <label className="sm:col-span-2">
        <span className="sr-only">Message</span>
        <textarea name="message" rows={4} placeholder="Tell us about the project (leaks, storm damage, age of roof…)" className={field} />
      </label>
      <button className="rounded-md bg-copper px-7 py-4 font-display text-lg font-extrabold tracking-wide text-slate-ink uppercase transition hover:bg-copper-light sm:col-span-2">
        Request My Quote
      </button>
    </form>
  );
}
