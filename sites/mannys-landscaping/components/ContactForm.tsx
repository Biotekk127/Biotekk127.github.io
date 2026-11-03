"use client";

import { useState } from "react";
import { business } from "@/lib/business";

const field =
  "w-full rounded-xl border border-char/15 bg-white px-4 py-3 text-char placeholder:text-char/45 focus:border-grass focus:outline-none focus:ring-2 focus:ring-grass/30";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const d = new FormData(e.currentTarget);
    const services = d.getAll("service").join(", ");
    if (business.email) {
      const body = `Name: ${d.get("name")}\nPhone: ${d.get("phone")}\nAddress: ${d.get("address")}\nInterested in: ${services}\n\n${d.get("message")}`;
      window.location.href = `mailto:${business.email}?subject=${encodeURIComponent("Landscaping quote request")}&body=${encodeURIComponent(body)}`;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <div className="rounded-3xl bg-white p-8 shadow-xl shadow-char/5">
        <p className="font-display text-3xl font-extrabold">Got it, thanks!</p>
        <p className="mt-2 text-char/70">
          {business.ownerName} will get back to you soon. In a hurry? Call{" "}
          <a href={business.phoneHref} className="font-bold text-grass underline">
            {business.phone}
          </a>
          .
        </p>
        {!business.email && <p className="placeholder mt-4 rounded px-3 py-2">[PLACEHOLDER] Form not yet connected to the owner&apos;s email.</p>}
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="grid gap-4 rounded-3xl bg-white p-6 shadow-xl shadow-char/5 sm:grid-cols-2 sm:p-8">
      <input required name="name" aria-label="Name" autoComplete="name" placeholder="Your name" className={field} />
      <input required name="phone" aria-label="Phone" type="tel" autoComplete="tel" placeholder="Phone" className={field} />
      <input name="address" aria-label="Property address" autoComplete="street-address" placeholder="Property address" className={`${field} sm:col-span-2`} />
      <fieldset className="sm:col-span-2">
        <legend className="mb-2 text-sm font-semibold text-char/70">What are you interested in?</legend>
        <div className="flex flex-wrap gap-2">
          {business.services.map((s) => (
            <label key={s.title} className="cursor-pointer">
              <input type="checkbox" name="service" value={s.title} className="peer sr-only" />
              <span className="inline-block rounded-full border border-char/15 px-4 py-2 text-sm transition peer-checked:border-grass peer-checked:bg-grass peer-checked:text-white peer-focus-visible:ring-2 peer-focus-visible:ring-grass/40">
                {s.title}
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <textarea name="message" aria-label="Message" rows={4} placeholder="Tell us about the project" className={`${field} sm:col-span-2`} />
      <button className="rounded-xl bg-char px-7 py-4 font-display text-lg font-bold text-stone transition hover:bg-grass sm:col-span-2">Send quote request</button>
    </form>
  );
}
