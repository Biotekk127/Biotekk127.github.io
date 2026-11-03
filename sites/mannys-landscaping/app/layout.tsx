import type { Metadata, Viewport } from "next";
import { Inter, Inter_Tight, Instrument_Serif } from "next/font/google";
import "./globals.css";
import { business, fullAddress } from "@/lib/business";

const tight = Inter_Tight({ subsets: ["latin"], weight: ["500", "600", "700"], variable: "--font-tight" });
const instrument = Instrument_Serif({ subsets: ["latin"], weight: "400", style: ["normal", "italic"], variable: "--font-instrument" });
const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

const description = `${business.name}: paver walkways, stone steps, landscaping, lawn mowing and leaf cleanup in ${business.address.city}, CT. Call ${business.phone}.`;

export const metadata: Metadata = {
  title: `${business.name} | Landscaping & Hardscape in ${business.address.city}, CT`,
  description,
  openGraph: { title: business.name, description, type: "website", images: ["/photos/walkway.jpg"] },
};

export const viewport: Viewport = { themeColor: "#0c1526" };

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
    <html lang="en" className={`${tight.variable} ${instrument.variable} ${inter.variable}`}>
      <body>
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
        {children}
      </body>
    </html>
  );
}
