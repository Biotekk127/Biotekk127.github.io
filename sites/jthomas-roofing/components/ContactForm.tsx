"use client";

import { useState } from "react";
import { business } from "@/lib/business";

const field =
  "w-full rounded-lg border border-paper/20 bg-paper/10 px-4 py-3 text-paper placeholder:text-paper/50 focus:border-brass focus:outline-none focus:ring-2 focus:ring-brass/40";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(e.currentTarget)) as Record<string, string>;
    if (business.email) {
      const body = `Name: ${d.name}\nPhone: ${d.phone}\nAddress: ${d.address}\nHouse age: ${d.age}\n\n${d.message}`;
      window.location.href = `mailto:${business.email}?subject=${encodeURIComponent("Roof quote request")}&body=${encodeURIComponent(body)}`;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <div className="rounded-2xl border border-brass/40 bg-paper/10 p-8 text-paper">
        <p className="font-serif text-3xl">Thank you.</p>
        <p className="mt-2 text-paper/80">
          We&apos;ll be in touch soon. For anything urgent, call{" "}
          <a href={business.phoneHref} className="font-semibold text-brass underline">
            {business.phone}
          </a>
          .
        </p>
        {!business.email && <p className="placeholder mt-4 rounded px-3 py-2">[PLACEHOLDER] Form not yet connected to the owner&apos;s email.</p>}
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
      <input required name="name" aria-label="Name" autoComplete="name" placeholder="Your name" className={field} />
      <input required name="phone" aria-label="Phone" type="tel" autoComplete="tel" placeholder="Phone" className={field} />
      <input name="address" aria-label="Property address" autoComplete="street-address" placeholder="Property address" className={`${field} sm:col-span-2`} />
      <select name="age" aria-label="Roughly how old is the house?" defaultValue="" className={`${field} sm:col-span-2`}>
        <option value="" disabled>
          Roughly how old is the house?
        </option>
        {["Built before 1940", "1940 – 1980", "1980 – 2000", "After 2000", "Not sure"].map((o) => (
          <option key={o} className="text-ink">
            {o}
          </option>
        ))}
      </select>
      <textarea name="message" aria-label="Message" rows={4} placeholder="What's going on with the roof?" className={`${field} sm:col-span-2`} />
      <button className="rounded-full bg-brass px-8 py-4 font-semibold text-ink transition hover:bg-paper sm:col-span-2">Send my quote request</button>
    </form>
  );
}
