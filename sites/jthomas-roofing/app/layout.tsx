import type { Metadata, Viewport } from "next";
import { Fraunces, Work_Sans } from "next/font/google";
import "./globals.css";
import { business, fullAddress } from "@/lib/business";

const fraunces = Fraunces({ subsets: ["latin"], style: ["normal", "italic"], variable: "--font-fraunces" });
const work = Work_Sans({ subsets: ["latin"], variable: "--font-work" });

const description = `${business.name} — roof replacement and roof repair in ${business.address.city}, CT, including older and historic homes. Call ${business.phone}.`;

export const metadata: Metadata = {
  title: `${business.name} | Roofing Contractor in ${business.address.city}, CT`,
  description,
  openGraph: { title: business.name, description, type: "website" },
};

export const viewport: Viewport = { themeColor: "#2e4a3b" };

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "RoofingContractor",
  name: business.name,
  telephone: business.phone,
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
  description: `Roofing contractor at ${fullAddress}.`,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${fraunces.variable} ${work.variable}`}>
      <body>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
        {children}
      </body>
    </html>
  );
}
