# Wholesale Desk

A personal, local-only toolkit for wholesaling Connecticut houses and vacant land through assignment deals. It's built for one person, runs on your own computer and costs nothing:

- **No paid APIs, no API keys, no accounts, no subscriptions, no cloud.**
- **No dependencies to install.** It uses only what comes with Node.js (the built-in `node:sqlite` database and `node:http` server). `npm install` isn't needed.
- **Your data stays on your machine** in `data/wholesale.db`, with photos in `data/uploads/` and the import log in `data/import.log`. The `data/` folder is git-ignored, so your deals are never committed.
- **One kind of outbound request:** when you click **Import**, the app downloads the one Zillow, Realtor.com or Redfin page you pasted. Nothing else ever leaves your computer. The owner-lookup links open in *your browser*; the app itself never contacts those sites.
- **Nothing is invented.** Every number on screen is either something you typed or a value read from a page you imported, and the import shows exactly where on the page each value came from. Blank inputs stay blank and are never treated as $0.

## Run it

1. Install **Node.js 22.13 or newer** from https://nodejs.org (the LTS download is fine).
2. In a terminal:
   ```
   cd wholesale-app
   npm start
   ```
3. Open **http://127.0.0.1:3000** in your browser.

The server listens on `127.0.0.1` only, so other devices on your network can't reach it. To use a different port, run `PORT=4000 npm start` (on Windows PowerShell: `$env:PORT=4000; npm start`).

To back up your data, copy the `data/` folder while the app is stopped.

Run the tests with `npm test`.

## Features

| Area | What it does |
|---|---|
| **Leads** | Add properties by hand: address, parcel ID, owner, asking price, source, notes, links and photos. The pipeline runs New → Researching → Contacted → Offer Made → Under Contract → Assigned → Closed, with Dead as an exit. One search box covers every field, and you can filter by status, type or source. |
| **Listing import** | Paste a Zillow, Realtor.com or Redfin URL to auto-fill list price, beds, baths, sqft, lot size, property type and the contact phone. You review every value, with its source, before it's saved. The phone is labelled **"listing contact (usually the agent)"**, or **"seller direct"** if the listing is marked FSBO. If the fetch fails, the app tells you exactly why and fills in nothing. |
| **Owner lookup** | One-click links to TruePeopleSearch (by address and by owner name), Google (address in quotes), and Google searches for the town assessor and the town clerk's land records. You can save each town's assessor URL once and reuse it on every lead in that town. There are also fields for the owner's phone and email and a note on where you found them. |
| **Analyzer** | **House:** MAO = (ARV × 0.70) − repairs − fee, with each step of the math shown, compared against the asking price. **Land:** max offer = builder resale value − fee, plus a 5-item buildability checklist. A land deal can't move to Offer Made or later until all 5 items are ticked. |
| **Comps** | Enter sold comps by hand. The app shows the low, median, average and high sale prices and the median $/sqft of the comps **you entered**. It's labelled as arithmetic on your own inputs, not an appraisal. You can push the median or average into the analyzer with one click. |
| **Buyers** | Cash buyers with contact details, a buy box (towns/ZIPs, price range, property types) and proof-of-funds notes. Each lead has a **Buyer matches** tab that shows who fits and why, and who doesn't fit and why. |
| **CT compliance** | A checklist for each deal: wholesaler registration, the written DCP disclosure signed by the seller **before** the contract, closing within 90 days of the contract, and an assignment clause. **Under Contract, Assigned and Closed are locked until the disclosure is ticked**, and the app explains why in plain language. It also warns when the dates you entered break the 90-day rule or show the disclosure signed after the contract. |
| **Dashboard** | Lead counts by stage, offers made, contracts signed, fees collected and conversion rates. Each figure states what it's counting. |

The status gates are enforced on the server, not just in the UI. They can't be bypassed by skipping stages, and you can't untick a required box while the lead is past that gate (move the lead back first).

> The CT checklist is a reminder tool, not legal advice. Confirm current requirements with the CT Department of Consumer Protection or a CT real estate attorney.

## Listing import: how it works and how it breaks

Real-estate sites change their pages often and actively block automated requests, so **expect imports to fail sometimes**, especially on Zillow. When an import fails you get the exact reason:

- **HTTP 403 / 429**: the site's bot protection refused the request.
- **Bot-check page**: a captcha or "verify you're human" page came back instead of the listing (PerimeterX, DataDome, Cloudflare and others are detected). Nothing on that page is used.
- **Could not download**: you're offline, DNS failed or the connection timed out.
- **Layout changed**: the page loaded but none of the expected data was where the parser looks. The notes list which data blocks were missing.
- **Parser crashed**: the error message tells you which parser file to update.

In every one of these cases, nothing is filled in. Open the listing in your browser and type the details on the **Listing import** tab instead.

Every import attempt, successful or not, is appended to `data/import.log` with the URL, every failure message and the exact source path of every value. Recent attempts also appear on each lead's **Listing import** tab.

Each site has its own parser file, so a layout change on one site breaks only that file:

```
lib/parsers/common.js    shared helpers (script/JSON-LD extraction, phone normalizing, bot-wall detection)
lib/parsers/zillow.js
lib/parsers/realtor.js
lib/parsers/redfin.js
lib/importer.js          fetch, pick the parser, collect results, label the phone, report what's missing
```

### Parser dependencies (what each parser reads)

The first source that has a value wins. A field that none of these sources has is reported as missing, never guessed.

**zillow.js**
- `<script id="__NEXT_DATA__">` → `props.pageProps.componentProps.gdpClientCache` (a JSON *string*). The parser takes the first entry that has a `.property` object. It falls back to `props.pageProps.gdpClientCache`, then to the older `<script id="hdpApolloPreloadedData">` → `apiCache`.
  - `property.price` → list price; `bedrooms`, `bathrooms`, `livingArea` → beds, baths, sqft
  - `lotAreaValue` + `lotAreaUnits`, otherwise `lotSize` (sqft), otherwise `resoFacts.lotSize` → lot size
  - `homeType` → property type; `streetAddress`, `city`, `state`, `zipcode`, `parcelId` / `resoFacts.parcelNumber`
  - Phone: `attributionInfo.agentPhoneNumber`, then `attributionInfo.brokerPhoneNumber`, then `listed_by.phone`
  - FSBO: `listingSubType.isFSBO` / `is_FSBO`, or "For Sale By Owner" in the page's own `og:title` / meta description. The site-wide menu, which says "For Sale by Owner" on every page, is deliberately ignored.
- Fallback: JSON-LD (`<script type="application/ld+json">`) `offers.price`, `floorSize.value`, `numberOfBedrooms`, `numberOfBathroomsTotal`, `address.*`

**realtor.js**
- `<script id="__NEXT_DATA__">` → the first of these that holds a property: `props.pageProps.initialReduxState.propertyDetails`, `props.pageProps.property`, `props.pageProps.propertyDetails`, `props.pageProps.initialProps.property`
  - `list_price`; `description.beds`, `description.baths_consolidated` (otherwise `baths`), `description.sqft`, `description.lot_sqft`, `description.type`
  - `location.address.line / city / state_code / postal_code`
  - Phone: `advertisers[].phones[].number`, then `advertisers[].phone`, then `advertisers[].office.phones[].number`, then `consumer_advertisers[].phone`
  - FSBO: `source.type` containing "fsbo"/"by owner", `flags.is_fsbo`, or `og:title` / meta description wording
- Fallback: JSON-LD, the same as for Zillow

**redfin.js**
- JSON-LD: a `RealEstateListing`/`Product` node → `offers.price`; the residence node (or its `mainEntity`) → `numberOfBedrooms`, `numberOfBathroomsTotal`, `floorSize.value`, `address.*`, and `@type` SingleFamilyResidence → property type
- `<meta name="twitter:text:price|beds|baths|sqft">`
- Visible text: `Lot Size (Sq. Ft.): N`, `Lot Size (Acres): N`, `Lot Size: N unit` or `N acres Lot Size`
- Phone: **only** a phone number within 400 characters after the words "Listed by" (the listing agent block). Other numbers on the page, such as Redfin's own support line, are never used.
- FSBO: `og:title` / meta description wording, or "Listed by owner"

**Testing note:** the parser tests in `test/parsers.test.js` run against **synthetic** fixture pages in `test/fixtures/`. Those pages were built by hand to mirror each site's embedded-data structure and are not real listings. The parsers were written without access to live pages, so the first real import from each site is the true test. If a site has changed, the import screen and `data/import.log` will say what's missing. Save the page in your browser (Ctrl+S, "Webpage, HTML only"), update that site's parser, and add the saved page as a new fixture.

## Things deliberately left out (they would need paid services)

- Automatic owner skip tracing (BatchSkipTracing, PropStream and similar are paid). Use the free lookup links and paste the results in.
- Automatic MLS comps or AVM / "Zestimate"-style ARV. Comps are entered by hand.
- Automatic CT parcel, tax and assessor data (no free statewide API). Use the per-town assessor link.
- SMS and email blasts to buyers (Twilio, SendGrid and the like are paid). Buyer contact details are shown so you can reach out yourself.
- Maps and geocoding (most map APIs need keys). Comp distance is entered by hand.

## Project layout

```
server.js            local HTTP server + JSON API (127.0.0.1 only)
lib/db.js            SQLite schema and input cleaning (node:sqlite)
lib/importer.js      listing import pipeline
lib/parsers/*.js     one parser per site
shared/rules.js      statuses, gates, MAO math, ARV-from-comps, buyer matching (used by server AND browser)
public/              the UI (plain HTML/CSS/JS, no build step)
test/                node:test tests + synthetic fixtures
data/                your database, photos and import log (git-ignored, created on first run)
```
