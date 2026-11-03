# Manny's Landscaping — preview site

Built by CyberEdge Creations. Next.js (static export) + Tailwind + GSAP.

## Edit content
All business facts live in `lib/business.ts`. Anything still `null` / empty
renders on the page as a yellow `[PLACEHOLDER]` tag. Fill it from the Google profile.

## Add photos
Put the business's photos in `public/photos/` and list them in `business.photos`.

## Add the cinematic 3D storefront scroll
```bash
npm run frames -- path/to/storefront.mp4 160
npm run build
```
The hero switches to the scroll-scrubbed video automatically when `public/frames/manifest.json` exists.

## Run / deploy
```bash
npm install
npm run dev          # local
npx vercel deploy    # preview (Vercel project: cyberedge-mannys-landscaping, root: this folder)
```
