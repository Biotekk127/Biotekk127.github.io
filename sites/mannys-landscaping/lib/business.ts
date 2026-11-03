/**
 * Every fact about the business lives here.
 * null / empty values render on the site as visible [PLACEHOLDER] tags.
 *
 * Source: Google Business Profile (pasted by CyberEdge Creations, Nov 2026).
 * Profile is unclaimed; no hours or website listed.
 * Photos: the two Google photos were posted by a customer (Jose M.) —
 * get Manny's OK, or swap in his own photos, before launch.
 */

export const PLACEHOLDER = "[PLACEHOLDER]";

const q = encodeURIComponent("Manny's Landscaping LLC, 80 Young St, Willimantic, CT 06226");

export const business = {
  name: "Manny's Landscaping",
  legalName: "Manny's Landscaping LLC",
  ownerName: "Manny",
  category: "Landscaper",
  phone: "(860) 617-2556",
  phoneHref: "tel:+18606172556",
  email: null as string | null,
  address: { street: "80 Young St", city: "Willimantic", region: "CT", postal: "06226" },
  googleUrl: `https://www.google.com/maps/search/?api=1&query=${q}`,
  directionsUrl: `https://www.google.com/maps/dir/?api=1&destination=${q}`,
  mapEmbed: `https://maps.google.com/maps?q=${q}&z=15&output=embed`,

  rating: 4.0,
  reviewCount: 12,
  featuredReview: {
    name: "Jose",
    rating: 5,
    text: "Great work at a fair price. Recent walkway installed and back steps. Manny & crew worked hard with great attention to cutting and detail. We plan to use Manny in he spring for additional landscaping work. Highly recommend",
  },
  // Highlight quote Google shows in the review summary (reviewer not shown there).
  highlightQuote: "Hung in there well into dark to get the work done.",

  photos: [
    { src: "/photos/walkway.jpg", alt: "Curved paver walkway with a charcoal soldier-course border leading to a porch" },
    { src: "/photos/steps.jpg", alt: "Granite block steps with paver treads leading up to a side door" },
  ],

  // ---- Not on the Google profile yet ----
  about: null as string | null,
  serviceArea: null as string | null,
  yearsInBusiness: null as number | null,
  hours: null as { days: string; time: string }[] | null,

  services: [
    { title: "Paver Walkways", body: "Curved or straight walkways with clean borders and precise cuts, laid to last.", tag: "Hardscape" },
    { title: "Stone Steps", body: "Granite and paver steps that make slopes and side doors easy and safe to reach.", tag: "Hardscape" },
    { title: "Landscaping", body: "Planting, beds and yard projects to get your property looking its best.", tag: "Spring" },
    { title: "Lawn Mowing & Weeding", body: "Mowing, trimming and weed cleanup on lawns and walkways.", tag: "Summer" },
    { title: "Leaf Cleanup", body: "Fall leaf removal so the yard is clean before winter sets in.", tag: "Fall" },
  ],
};

export const fullAddress = `${business.address.street}, ${business.address.city}, ${business.address.region} ${business.address.postal}`;
