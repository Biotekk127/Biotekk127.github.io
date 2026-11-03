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
  tagline: "Roofing, decks & home renovations for Connecticut homeowners",
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
  rating: 5.0 as number | null,
  reviewCount: 24 as number | null,
  yearsInBusiness: null as number | null,
  ownerName: "Shaun" as string | null,
  serviceArea: null as string | null, // e.g. "Hartford & Tolland County"
  hours: null as { days: string; time: string }[] | null,
  // Verbatim from Google (only reviews whose full text was visible).
  reviews: [
    { name: "Dawn", rating: 5, text: "Shaun and his team did a great job on our roof.  He quoted the job on a Saturday and they began the following week.  The team arrived on time and completed the job as promised.  The worksite was cleaned before they left.  Shaun promises and delivers!  We would not hesitate to work with Shaun again in the future!" },
    { name: "Jan Marie", rating: 5, text: "Shaun fixed the flashing around our chimney which we needed desperately because our roof was leaking. He was able to get it done very quickly, for which we were grateful because it rained very hard the next day. No more leaks! He did a great job, was very professional, and his prices are reasonable. Would definitely hire him again!" },
    { name: "Amy", rating: 5, text: "Shaun and his team just completed the roof on my house, from the quote to finish everything was incredibly easy.  His team was on time, professional, and wonderful to work with, I\u2019ll definitely be recommending him to anyone who is in need of a new roof!" },
    { name: "Eric", rating: 5, text: "Shaun and his crew did a great job!  Work was done on time and on budget.  Shaun keep me in the loop at all time, and was very responsive to calls/emails throughout the process.  I would recommend him if you need any work done!" },
    { name: "Carol", rating: 5, text: "We had our deck rebuilt by Shaun and his team. It is beautiful. High quality work great attention to detail. Shaun was very hands on and would pick up the phone if I had questions. I will be using him for other home projects. I absolutely love my new deck. Thank you Shaun and Derrick." },
    { name: "Lan", rating: 5, text: "It has been almost a year since Shaun tore down our old wood deck and put in a Trek deck. We absolutely love it and get compliments on it all the time. Shaun was extremely responsive throughout the whole project. Highly recommend!" },
  ] as Review[],
  // Short verbatim quotes for the scrolling ribbon.
  shortQuotes: [
    { name: "Hailey", text: "High quality work at great prices! Will definitely be using them again in the future." },
    { name: "James", text: "Fast, cost effective work. Highly recommended." },
    { name: "Andrea", text: "Super fast, professional and great job on my roof repairs and railing build" },
    { name: "Christine", text: "Very professional, good work and good communication!" },
    { name: "Sarah", text: "Amazing work!!" },
  ],
  // Each point is backed by what customers wrote in their Google reviews.
  highlights: [
    { title: "Same-day quotes", body: "Customers describe Shaun showing up the same day they called, even in the rain." },
    { title: "Insurance claim help", body: "Guidance on filing a claim with your insurer, with you every step of the way." },
    { title: "Clean job sites", body: "Crews arrive on time and clean the worksite before they leave." },
    { title: "Fair, reasonable prices", body: "Work done on time and on budget, at prices customers call reasonable." },
  ],
  // Their own photos go in /public/photos and are listed here.
  photos: [] as { src: string; alt: string }[],
  // Short story for the About section, from the owner / profile description.
  about: "CT Homes and Roofing is a South Windsor contractor run by owner Shaun, who stays hands-on from the first quote to the final cleanup. Homeowners hire his team for new roofs, leak repairs and chimney flashing, and then call them back for decks, bathrooms and interior work." as string | null,

  services: [
    { title: "Roof Replacement", body: "Complete tear-off and new roof installation, quoted fast and finished as promised.", icon: "roof" },
    { title: "Roof Repair & Leaks", body: "Leaks, chimney flashing, missing shingles and storm damage, fixed before the next rain.", icon: "repair" },
    { title: "Decks & Railings", body: "Old wood decks torn out and rebuilt, including composite decking and new railings.", icon: "deck" },
    { title: "Bathroom Remodels", body: "Bathroom makeovers planned around what you need and want from the space.", icon: "bath" },
    { title: "Interior Painting", body: "Respectful, tidy crews who get interior painting done professionally and on time.", icon: "paint" },
    { title: "Siding", body: "New siding and siding repair that protects the house and refreshes its curb appeal.", icon: "siding" },
  ],
};

export const fullAddress = `${business.address.street}, ${business.address.city}, ${business.address.region} ${business.address.postal}`;
