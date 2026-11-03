import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, DM_Sans } from "next/font/google";
import "./globals.css";
import { business, fullAddress } from "@/lib/business";

const bricolage = Bricolage_Grotesque({ subsets: ["latin"], variable: "--font-bricolage" });
const dm = DM_Sans({ subsets: ["latin"], variable: "--font-dm" });

const description = `${business.name} — paver walkways, stone steps, landscaping, lawn mowing and leaf cleanup in ${business.address.city}, CT. Call ${business.phone}.`;

export const metadata: Metadata = {
  title: `${business.name} | Landscaping & Walkways in ${business.address.city}, CT`,
  description,
  openGraph: { title: business.name, description, type: "website", images: ["/photos/walkway.jpg"] },
};

export const viewport: Viewport = { themeColor: "#0f1a2e" };

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "LandscapingBusiness",
  name: business.legalName,
  telephone: business.phone,
  image: "/photos/walkway.jpg",
  address: {
    "@type": "PostalAddress",
    streetAddress: business.address.street,
    addressLocality: business.address.city,
    addressRegion: business.address.region,
    postalCode: business.address.postal,
    addressCountry: "US",
  },
  hasMap: business.googleUrl,
  aggregateRating: { "@type": "AggregateRating", ratingValue: business.rating, reviewCount: business.reviewCount },
  description: `Landscaping and hardscaping at ${fullAddress}.`,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${bricolage.variable} ${dm.variable}`}>
      <body>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
        {children}
      </body>
    </html>
  );
}
