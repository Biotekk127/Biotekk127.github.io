import type { Metadata, Viewport } from "next";
import { Archivo, Inter } from "next/font/google";
import "./globals.css";
import { business, fullAddress } from "@/lib/business";

const archivo = Archivo({ subsets: ["latin"], weight: ["600", "800", "900"], variable: "--font-archivo" });
const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

const description = `${business.name} — roofing, roof repair, decks and home renovations in ${business.address.city}, ${business.address.region}. Call ${business.phone} for a quote.`;

export const metadata: Metadata = {
  title: `${business.name} | Roofing Contractor in ${business.address.city}, CT`,
  description,
  openGraph: { title: business.name, description, type: "website" },
};

export const viewport: Viewport = { themeColor: "#0c1622" };

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
  geo: { "@type": "GeoCoordinates", latitude: business.geo.lat, longitude: business.geo.lng },
  hasMap: business.googleUrl,
  ...(business.rating && business.reviewCount
    ? { aggregateRating: { "@type": "AggregateRating", ratingValue: business.rating, reviewCount: business.reviewCount } }
    : {}),
  description: `Roofing and home renovation contractor at ${fullAddress}.`,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${archivo.variable} ${inter.variable}`}>
      <body>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
        {children}
      </body>
    </html>
  );
}
