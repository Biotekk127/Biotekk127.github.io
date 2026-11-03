/**
 * Every fact about the business lives here.
 * null / empty values render on the site as visible [PLACEHOLDER] tags.
 *
 * Source: Google Business Profile (pasted by CyberEdge Creations, Nov 2026).
 * The profile is unclaimed and lists no hours, website or photos.
 */

export const PLACEHOLDER = "[PLACEHOLDER]";

export type Review = { name: string; rating: number; text: string };

const q = encodeURIComponent("Jthomas Roofing, 42 Boston Post Rd, Willimantic, CT 06226");

export const business = {
  name: "JThomas Roofing", // Google lists it as "Jthomas Roofing" — confirm preferred spelling
  category: "Roofing Contractor",
  phone: "(860) 465-9127",
  phoneHref: "tel:+18604659127",
  email: null as string | null,
  address: { street: "42 Boston Post Rd", city: "Willimantic", region: "CT", postal: "06226" },
  googleUrl: `https://www.google.com/maps/search/?api=1&query=${q}`,
  directionsUrl: `https://www.google.com/maps/dir/?api=1&destination=${q}`,
  mapEmbed: `https://maps.google.com/maps?q=${q}&z=15&output=embed`,

  rating: 5.0,
  reviewCount: 1,
  reviews: [
    { name: "Hank", rating: 5, text: "We have a house built in 1904 and they did a top notch job.  I would call them again!" },
  ] as Review[],

  // ---- Not on the Google profile yet ----
  ownerName: null as string | null,
  about: null as string | null,
  serviceArea: null as string | null,
  yearsInBusiness: null as number | null,
  hours: null as { days: string; time: string }[] | null,
  photos: [] as { src: string; alt: string }[],

  services: [
    {
      title: "Roof Replacement",
      body: "A full tear-off and a new roof, installed with care for the house underneath it.",
    },
    {
      title: "Roof Repair",
      body: "Leaks, worn or missing shingles, and flashing, repaired before they turn into bigger damage.",
    },
    {
      title: "Older & Historic Homes",
      body: "Steep pitches, odd angles and century-old framing. Older houses need a crew that takes its time and gets it right.",
    },
  ],
};

export const fullAddress = `${business.address.street}, ${business.address.city}, ${business.address.region} ${business.address.postal}`;
