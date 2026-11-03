/**
 * Every fact about the business lives here.
 * Anything not confirmed from a real source is marked PLACEHOLDER
 * and rendered visibly on the site so it can't slip into a pitch.
 *
 * Confirmed so far (public directory listings + Google Maps link):
 *   name, street address, phone, map coordinates, category (roofing / siding / renovations)
 */

export const PLACEHOLDER = "[PLACEHOLDER]";

export type Review = {
  name: string; // reviewer first name, as shown on Google
  rating: number; // 1–5
  text: string; // verbatim
  when?: string; // e.g. "3 months ago"
};

export const business = {
  name: "CT Homes and Roofing",
  shortName: "CT Homes",
  category: "Roofing Contractor",
  tagline: "Roofs, siding & home renovations for Connecticut homeowners",
  phone: "(860) 830-8412",
  phoneHref: "tel:+18608308412",
  email: null as string | null, // PLACEHOLDER
  address: {
    street: "819 Ellington Rd",
    city: "South Windsor",
    region: "CT",
    postal: "06074",
  },
  geo: { lat: 41.811615, lng: -72.607428 },
  googleUrl: "https://maps.google.com/?cid=15236751921593868496",
  directionsUrl:
    "https://www.google.com/maps/dir/?api=1&destination=819+Ellington+Rd,+South+Windsor,+CT+06074",

  // ---- Fill from the Google Business Profile ----
  rating: null as number | null, // e.g. 4.9
  reviewCount: null as number | null, // e.g. 87
  yearsInBusiness: null as number | null,
  ownerName: null as string | null,
  serviceArea: null as string | null, // e.g. "Hartford & Tolland County"
  hours: null as { days: string; time: string }[] | null,
  reviews: [] as Review[],
  // Their own photos go in /public/photos and are listed here.
  photos: [] as { src: string; alt: string }[],
  // Short story for the About section, from the owner / profile description.
  about: null as string | null,

  services: [
    {
      title: "Roof Replacement",
      body: "Complete tear-off and new roof installation, from old shingles down to the deck and back up again.",
      icon: "roof",
    },
    {
      title: "Roof Repair",
      body: "Leaks, missing shingles, flashing and storm damage, found and fixed before small problems become big ones.",
      icon: "repair",
    },
    {
      title: "Siding",
      body: "New siding and siding repair that protects the house and refreshes how it looks from the street.",
      icon: "siding",
    },
    {
      title: "Home Renovations",
      body: "Exterior and interior improvement projects handled by one local crew you already trust with your roof.",
      icon: "reno",
    },
  ],
};

export const fullAddress = `${business.address.street}, ${business.address.city}, ${business.address.region} ${business.address.postal}`;
