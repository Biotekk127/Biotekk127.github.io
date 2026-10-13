# Agent workflow scripts

Claude Code `Workflow` scripts used to build this game with parallel agents. They hard-code
the scratch paths of the session that created them; update `ROOT` / `SCRATCH` / `LUAU` at the
top of each file when running them in a new session.

| Script | What it does |
|---|---|
| `polish-one.js` | Fresh-eyes art-director polish of one character (`args.character`) |
| `boss-audit.js` | Boss reviews all 12 characters, writes `tools/charlab/STYLE_GUIDE.md` + fix lists |
| `boss-fix-one.js` | Applies the style guide + one character's fix list |
| `boss-signoff.js` | Boss re-reviews the whole set and approves or sends back (`args.round`) |
| `phase2-stream.js` | Builds one Phase 2 workstream, two independent reviews, then fixes (`args.stream`) |
