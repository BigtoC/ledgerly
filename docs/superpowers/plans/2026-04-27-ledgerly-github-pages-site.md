# Ledgerly GitHub Pages Site Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Starlight-based GitHub Pages site for Ledgerly with a custom landing page, README-derived `Ledgerly Guide`, real screenshots, and a latest-release split-APK download flow while updating Android release automation to publish ABI-specific assets.

**Architecture:** Keep the Flutter app and the website isolated by adding a dedicated `site/` Astro workspace inside the repo. Use Starlight for guide content and navigation, a custom Astro homepage for the marketing surface, and a small pure TypeScript helper to classify GitHub release assets. The download card fetches the latest release at **Astro build time** (not client-side), producing fully static HTML with pre-resolved download URLs and checksums — no runtime API dependency, no loading state, no rate-limit exposure. A `workflow_run` trigger on `android-release.yml` in the Pages workflow rebuilds the site after each successful Android release, so the download card always resolves the latest APK.

**Tech Stack:** Astro, Starlight, TypeScript, plain CSS, Vitest, GitHub Actions, existing Flutter Android build pipeline.

---

## Locked Decisions

- Use a dedicated `site/` workspace instead of mixing Node files into the Flutter root.
- Use Yarn 4 with a committed `site/yarn.lock` and `packageManager` metadata in `site/package.json`.
- Use Starlight + custom CSS only. Do not add Tailwind unless the homepage styling proves blocked without it.
- Put the public guide under `site/src/content/docs/ledgerly-guide/` as four Markdown pages.
- Keep Flutter CI unchanged; add dedicated site validation and Pages deployment workflows instead of forcing Node work into `.github/workflows/ci.yml`.
- Update Android release automation to publish split APKs only (no universal APK), using predictable filenames that the site can parse. Each release must also include a SHA-256 checksum manifest (`ledgerly-<tag>-checksums.txt`). Existing users updating from a prior universal APK must pick the correct ABI; document this in the first split-APK release notes.
- Fetch the latest release from `https://api.github.com/repos/BigtoC/ledgerly/releases/latest` at **Astro build time** (not client-side runtime). The `ApkDownloadCard` renders static HTML with pre-resolved download URLs and checksums — no client-side fetch, no loading state. The `github-pages.yml` workflow triggers via `workflow_run` on `android-release.yml` completing successfully, so the Pages build always runs after APK assets are uploaded and the latest release is resolvable.

## References To Keep Open

- Spec: `docs/superpowers/specs/2026-04-27-ledgerly-github-pages-design.md`
- Source content: `README.md` (`## User handbook`, status text, MVP limitations)
- Existing release workflow: `.github/workflows/android-release.yml`
- Astro GitHub Pages guide: `https://docs.astro.build/en/guides/deploy/github/`
- Starlight guides: `https://starlight.astro.build/guides/pages/`, `https://starlight.astro.build/guides/sidebar/`, `https://starlight.astro.build/guides/project-structure/`

## File Map

- Modify: `.gitignore` — ignore `site/` build artifacts and local Node output.
- Modify: `.github/workflows/android-release.yml` — build split APKs, rename them deterministically, generate SHA-256 checksums manifest, upload all assets.
- Modify: `README.md` — add contributor-facing website commands and deployment notes.
- Create: `.github/workflows/site-check.yml` — validate the site on PRs and relevant pushes.
- Create: `.github/workflows/github-pages.yml` — build and deploy `site/` to GitHub Pages.
- Create: `site/package.json` — Node scripts and dependencies.
- Create: `site/yarn.lock` — committed lockfile for CI and Pages builds.
- Create: `site/tsconfig.json` — strict Astro TypeScript config.
- Create: `site/astro.config.mjs` — `site`, `base`, Starlight integration, sidebar, custom CSS.
- Create: `site/src/content.config.ts` — Starlight content collection config.
- Create: `site/src/styles/custom.css` — Starlight theme variables and homepage styles.
- Create: `site/src/pages/index.astro` — custom product homepage.
- Create: `site/src/components/ScreenshotGallery.astro` — display real app screenshots with captions.
- Create: `site/src/components/ApkDownloadCard.astro` — build-time static download card; fetches latest release at `astro build` time.
- Create: `site/src/lib/apk-release.ts` — pure helper for parsing release assets and recommending an APK.
- Create: `site/src/lib/apk-release.test.ts` — unit tests for split-APK selection logic.
- Create: `site/src/assets/screenshots/splash.png`
- Create: `site/src/assets/screenshots/home.png`
- Create: `site/src/assets/screenshots/transaction-form.png`
- Create: `site/src/assets/screenshots/accounts.png`
- Create: `site/src/assets/screenshots/settings.png`
- Create: `site/src/content/docs/ledgerly-guide/getting-started.md`
- Create: `site/src/content/docs/ledgerly-guide/main-screens.md`
- Create: `site/src/content/docs/ledgerly-guide/daily-usage.md`
- Create: `site/src/content/docs/ledgerly-guide/mvp-limitations.md`

## Chunk 1: Site Workspace And Starlight Shell

### Task 1: Bootstrap the `site/` workspace

**Files:**
- Modify: `.gitignore`
- Create: `site/package.json`
- Create: `site/tsconfig.json`
- Create: `site/yarn.lock`

**Why this task exists:** The repo currently has no Node workspace, no lockfile, and no `site/` folder. Build reproducibility must land before any page or workflow work.

- [ ] **Step 1: Add Node artifact ignore rules for the new workspace**

Append these entries near the other tool-specific ignores in `.gitignore`:

```gitignore
site/node_modules/
site/dist/
site/.astro/
```

- [ ] **Step 2: Create `site/package.json` with the minimal scripts and packages**

Write `site/package.json` with a small, explicit script surface:

```json
{
  "name": "ledgerly-site",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "check": "astro check",
    "test": "vitest run"
  },
  "dependencies": {
    "astro": "^5.0.0",
    "@astrojs/starlight": "^0.30.0"
  },
  "devDependencies": {
    "@astrojs/check": "^0.9.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.0.0",
    "vitest": "^3.0.0"
  }
}
```

Do not add Tailwind, React, or extra integrations yet.

- [ ] **Step 3: Create a strict TypeScript config for Astro**

Write `site/tsconfig.json`:

```json
{
  "extends": "astro/tsconfigs/strict",
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist"]
}
```

**Note:** `astro/tsconfigs/strict` is the correct path in Astro 5. If the install in Step 4 produces a "Cannot find tsconfig" error, check the Astro 5 docs — the path may have changed to `astro/tsconfigs/strictest`. Adjust accordingly.

- [ ] **Step 4: Install the site dependencies and generate the lockfile**

Run: `corepack enable && yarn --cwd site install`

Expected:
- command exits `0`
- `site/yarn.lock` is created
- `site/node_modules/` is populated locally

- [ ] **Step 5: Sanity-check the installed Astro CLI before adding app code**

Run: `yarn --cwd site astro --version`

Expected:
- command exits `0`
- prints an Astro version string

- [ ] **Step 6: Commit the bootstrap-only change**

```bash
git add .gitignore site/package.json site/yarn.lock site/tsconfig.json
git commit -m "build(site): scaffold astro workspace"
```

### Task 2: Add the Starlight shell, base config, and route skeleton

**Files:**
- Create: `site/astro.config.mjs`
- Create: `site/src/content.config.ts`
- Create: `site/src/styles/custom.css`
- Create: `site/src/pages/index.astro`
- Create: `site/src/content/docs/ledgerly-guide/getting-started.md`

**Why this task exists:** The site needs a valid Astro + Starlight shell before content or workflows can be tested.

- [ ] **Step 1: Configure Astro and Starlight for GitHub Project Pages**

Write `site/astro.config.mjs`:

```js
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://bigtoc.github.io',
  base: '/ledgerly',
  integrations: [
    starlight({
      title: 'Ledgerly',
      description: 'Private, local-first expense tracking.',
      customCss: ['./src/styles/custom.css'],
      sidebar: [
        { label: 'Home', link: '/' },
        {
          label: 'Ledgerly Guide',
          items: [
            { slug: 'ledgerly-guide/getting-started' }
          ]
        }
      ],
      social: {
        github: 'https://github.com/BigtoC/ledgerly',
      },
    })
  ]
});
```

- [ ] **Step 2: Add the required Starlight content collection config**

Write `site/src/content.config.ts`:

```ts
import { defineCollection } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema(),
  }),
};
```

- [ ] **Step 3: Add custom CSS variables and minimal shared styles**

Create `site/src/styles/custom.css` with two responsibilities only:

```css
:root {
  --sl-color-accent-low: #23141f;
  --sl-color-accent: #d56ea2;
  --sl-color-accent-high: #f8c8df;
  --sl-color-gray-1: #f8f4f6;
  --sl-color-gray-7: #2b1828;
  --sl-color-gray-8: #20141f;
  --sl-color-gray-9: #140d14;
}

.home-shell {
  display: grid;
  gap: 3rem;
}

.home-hero,
.home-section {
  display: grid;
  gap: 1rem;
}
```

Keep homepage-specific selectors here; do not add a CSS framework.

- [ ] **Step 4: Create a minimal homepage route that proves custom pages work**

Write `site/src/pages/index.astro` as a small placeholder using Starlight’s page shell:

```astro
---
import StarlightPage from '@astrojs/starlight/components/StarlightPage.astro';
---

<StarlightPage
  frontmatter={{
    title: 'Ledgerly',
    description: 'Private, local-first expense tracking.',
  }}
  hasSidebar={false}
>
  <div class="home-shell">
    <section class="home-hero">
      <h1>Ledgerly</h1>
      <p>Private expense tracking in a few taps.</p>
      <p><a href="./ledgerly-guide/getting-started/">Open the Ledgerly Guide</a></p>
    </section>
  </div>
</StarlightPage>
```

Use relative links (`./ledgerly-guide/getting-started/`) inside custom pages so the Project Pages `base` does not get bypassed.

- [ ] **Step 5: Create the first guide page so Starlight can build the docs collection**

Write `site/src/content/docs/ledgerly-guide/getting-started.md`:

```md
---
title: Getting Started
description: What Ledgerly is and how to begin using it.
sidebar:
  order: 1
---

Ledgerly is a private, local-first expense tracker for fast manual bookkeeping.
```

- [ ] **Step 6: Run type and build verification for the shell**

Run: `yarn --cwd site check`

Expected:
- exits `0`
- no Starlight content-schema errors

Run: `yarn --cwd site build`

Expected:
- exits `0`
- `site/dist/index.html` exists
- `site/dist/ledgerly-guide/getting-started/index.html` exists

**Note:** Do not open these files directly in a browser (`file://`) to check links — the `base: '/ledgerly'` config bakes the subpath into all asset URLs, which will appear broken when opened as files. Use `yarn --cwd site preview` to verify links correctly under the configured base path.

- [ ] **Step 7: Commit the shell once both commands pass**

```bash
git add site/astro.config.mjs site/src/content.config.ts site/src/styles/custom.css site/src/pages/index.astro site/src/content/docs/ledgerly-guide/getting-started.md
git commit -m "build(site): add starlight shell"
```

## Chunk 2: Content, Screenshots, And Landing Page

### Task 3: Split the README handbook into the public `Ledgerly Guide`

**Files:**
- Modify: `site/astro.config.mjs`
- Modify: `site/src/content/docs/ledgerly-guide/getting-started.md`
- Create: `site/src/content/docs/ledgerly-guide/main-screens.md`
- Create: `site/src/content/docs/ledgerly-guide/daily-usage.md`
- Create: `site/src/content/docs/ledgerly-guide/mvp-limitations.md`

**Why this task exists:** The site’s guide is the README handbook republished for end users, not contributor docs.

- [ ] **Step 1: Expand `getting-started.md` from the README’s product intro**

Copy and adapt these README sections into `site/src/content/docs/ledgerly-guide/getting-started.md`:

- `### What Ledgerly is`
- `### Core ideas`
- `### First-time setup`

Keep the tone user-facing. Remove repo-internal notes like Flutter/Dart prerequisites and CI commands.

- [ ] **Step 2: Create `main-screens.md` from the README screen descriptions**

Write `site/src/content/docs/ledgerly-guide/main-screens.md` with frontmatter:

```md
---
title: Main Screens
description: What each part of Ledgerly does.
sidebar:
  order: 2
---
```

Populate it from README sections:
- `#### Splash screen and day counter`
- `#### Home`
- `#### Add / Edit Transaction`
- `#### Accounts`
- `#### Categories`
- `#### Settings`

- [ ] **Step 3: Create `daily-usage.md` from the README example flow**

Write `site/src/content/docs/ledgerly-guide/daily-usage.md` with this frontmatter:

```md
---
title: Daily Usage
description: A simple example of recording spending in Ledgerly.
sidebar:
  order: 3
---
```

Then add the lunch example and a short “typical flow” summary.

- [ ] **Step 4: Create `mvp-limitations.md` from the non-goals section**

Write `site/src/content/docs/ledgerly-guide/mvp-limitations.md` from `### What Ledgerly does not do in the MVP`.

Use this short frontmatter block:

```md
---
title: MVP Limitations
description: What the current public build intentionally does not include.
sidebar:
  order: 4
---
```

- [ ] **Step 5: Update the Starlight sidebar to include all four guide pages**

Modify `site/astro.config.mjs` so the `Ledgerly Guide` group becomes:

```js
{
  label: 'Ledgerly Guide',
  items: [
    { slug: 'ledgerly-guide/getting-started' },
    { slug: 'ledgerly-guide/main-screens' },
    { slug: 'ledgerly-guide/daily-usage' },
    { slug: 'ledgerly-guide/mvp-limitations' }
  ]
}
```

- [ ] **Step 6: Re-run Starlight verification once all four guide pages exist**

Run: `yarn --cwd site check`

Expected:
- exits `0`
- no missing sidebar slug errors

Run: `yarn --cwd site build`

Expected:
- exits `0`
- these exact routes are emitted under `site/dist/ledgerly-guide/`:
  - `site/dist/ledgerly-guide/getting-started/index.html`
  - `site/dist/ledgerly-guide/main-screens/index.html`
  - `site/dist/ledgerly-guide/daily-usage/index.html`
  - `site/dist/ledgerly-guide/mvp-limitations/index.html`

- [ ] **Step 7: Commit the guide content as its own change**

```bash
git add site/src/content/docs/ledgerly-guide/*.md site/astro.config.mjs
git commit -m "docs(site): add ledgerly guide"
```

### Task 4: Build the custom homepage and screenshot gallery

**Files:**
- Modify: `site/src/pages/index.astro`
- Modify: `site/src/styles/custom.css`
- Create: `site/src/components/ScreenshotGallery.astro`
- Create: `site/src/assets/screenshots/splash.png`
- Create: `site/src/assets/screenshots/home.png`
- Create: `site/src/assets/screenshots/transaction-form.png`
- Create: `site/src/assets/screenshots/accounts.png`
- Create: `site/src/assets/screenshots/settings.png`

**Why this task exists:** The homepage is the product landing surface and needs real screenshots, not generic docs chrome.

- [ ] **Step 1: Capture and save the five real app screenshots using stable filenames**

Target files:

```text
site/src/assets/screenshots/splash.png
site/src/assets/screenshots/home.png
site/src/assets/screenshots/transaction-form.png
site/src/assets/screenshots/accounts.png
site/src/assets/screenshots/settings.png
```

Capture all five screenshots in portrait orientation from the same Android phone-sized viewport. Keep the system status bar visible, use the app's light theme consistently across all screenshots, and avoid mixing tablet and phone captures in the same gallery.

If Android emulator tooling is available, capture with `adb exec-out screencap -p > <target-file>` after navigating to each screen. If not, use the simulator/device screenshot tool and save each PNG to the exact path above.

- [ ] **Step 2: Create a dedicated screenshot gallery component**

Write `site/src/components/ScreenshotGallery.astro` using `astro:assets` so the homepage stays focused on layout, not image plumbing.

The component should render a list of screenshot cards with:
- image (use Astro's `<Image>` component for automatic optimization)
- screen name as a visible label
- one-sentence caption
- `alt` text following the pattern "Ledgerly <screen name> screen — <one-line description of what the screen shows>"

Specific alt text for each screenshot:
- `splash.png`: "Ledgerly splash screen — displays the number of days since tracking began"
- `home.png`: "Ledgerly home screen — shows the daily transaction list and account balance summary"
- `transaction-form.png`: "Ledgerly add transaction screen — calculator-style keypad with category and account selectors"
- `accounts.png`: "Ledgerly accounts screen — lists all accounts with their current balances"
- `settings.png`: "Ledgerly settings screen — currency, splash toggle, and app preferences"

If any screenshot is missing at build time, render a placeholder `<div>` with the same dimensions rather than a broken `<img>` tag.

Expected import shape:

```astro
---
import splash from '../assets/screenshots/splash.png';
import home from '../assets/screenshots/home.png';
import transactionForm from '../assets/screenshots/transaction-form.png';
import accounts from '../assets/screenshots/accounts.png';
import settings from '../assets/screenshots/settings.png';
---
```

- [ ] **Step 3: Replace the homepage placeholder with the real landing-page sections**

Update `site/src/pages/index.astro` so it includes:
- hero with app promise: “Track your spending privately. No cloud, no subscriptions, no data leaving your phone.”
- `ApkDownloadCard` as the primary CTA (Task 6 replaces the placeholder added in Task 2)
- secondary CTA: “Read the Ledgerly Guide” linking to `./ledgerly-guide/getting-started/`
- benefits grid (three items, sourced from the README “Core ideas” section): local-first privacy, zero-subscription model, fast manual entry
- `ScreenshotGallery`
- “How it works” steps (three steps maximum: install → add your first account → log a transaction)
- Android install note: “Ledgerly is distributed as an APK. Enable 'Install from unknown sources' in your Android settings, download the APK above, and tap to install.”
- MVP limitations **linked** to the guide page (`./ledgerly-guide/mvp-limitations/`) rather than inlined; a one-line note is enough: “See what the current build doesn't include yet →”

Use `StarlightPage` with `hasSidebar={false}` so the page inherits Starlight theme/header behavior while remaining custom.

- [ ] **Step 4: Extend `custom.css` only as far as the homepage needs**

Add homepage selectors for:
- two-column hero at `@media (min-width: 640px)`: text left, download card right
- below 640px: single-column stacked layout, hero text above card
- benefits grid: three columns at ≥640px, single column below
- screenshot gallery: two columns at ≥640px, single column below; `overflow-x: hidden` — no horizontal scroll
- minimum touch target 44px height for all download links and CTA buttons
- button and note styles that remain accessible in light and dark themes (use Starlight CSS custom properties for colors; avoid hardcoded hex in layout selectors)

Do not introduce a second global stylesheet.

- [ ] **Step 5: Run the site build and a manual local preview**

Run: `yarn --cwd site build`

Expected:
- exits `0`
- homepage and guide pages emit successfully

Run: `yarn --cwd site dev`

Expected:
- local preview URL appears
- homepage shows the five screenshots and guide link without broken assets

- [ ] **Step 6: Commit the landing-page UI once the preview looks correct**

```bash
git add site/src/pages/index.astro site/src/components/ScreenshotGallery.astro site/src/styles/custom.css site/src/assets/screenshots/*.png
git commit -m "feat(site): add landing page and screenshots"
```

## Chunk 3: Download Logic, Release Automation, And Delivery Workflows

### Task 5: Write the failing tests for split-APK asset selection

**Files:**
- Create: `site/src/lib/apk-release.test.ts`

**Why this task exists:** The GitHub release parsing rules are the easiest part of the site to silently regress, so they need a pure test seam.

- [ ] **Step 1: Write tests for filename classification and recommendation order**

Create `site/src/lib/apk-release.test.ts` with cases for:

```ts
import { describe, expect, it } from 'vitest';
import {
  classifyApkAssetName,
  collectApkAssets,
  recommendPrimaryAsset,
} from './apk-release';

describe('classifyApkAssetName', () => {
  it('detects arm64-v8a assets from release filenames', () => {
    expect(classifyApkAssetName('ledgerly-v1.0.0-arm64-v8a.apk')).toBe('arm64-v8a');
  });
});
```

Add coverage for:
- `armeabi-v7a` and `x86_64` classification
- ignoring non-APK assets (source archives, checksums.txt, etc.)
- `recommendPrimaryAsset` prefers `arm64-v8a` when present
- `recommendPrimaryAsset` falls back to `armeabi-v7a` then `x86_64` when preferred ABI is missing
- `recommendPrimaryAsset` returns `null` when no classified assets exist
- `collectApkAssets` handles partial asset lists (one or two ABIs, not necessarily three)

Do **not** add tests for `isAndroidUserAgent` — that function is removed from the public surface.

- [ ] **Step 2: Run the test suite before implementing the helper**

Run: `yarn --cwd site test`

Expected:
- FAIL
- error mentions missing `./apk-release` exports or module not found

### Task 6: Implement the release helper and interactive APK download card

**Files:**
- Create: `site/src/lib/apk-release.ts`
- Create: `site/src/components/ApkDownloadCard.astro`
- Modify: `site/src/pages/index.astro`

**Why this task exists:** The homepage needs a static, always-available download flow. Release data is fetched at Astro build time — no client-side API calls, no loading states, no runtime rate-limit exposure. The `github-pages.yml` workflow (Task 8) depends on `android-release.yml` via `workflow_run`, so the Pages build triggers only after APK assets are fully uploaded and the card can always resolve the latest release.

- [ ] **Step 1: Implement the pure helper module**

Write `site/src/lib/apk-release.ts` with a focused API surface:

```ts
export type ApkAbi = ‘arm64-v8a’ | ‘armeabi-v7a’ | ‘x86_64’;

export interface ReleaseAsset {
  name: string;
  browser_download_url: string;
}

export interface ClassifiedApkAsset {
  name: string;
  url: string;
  abi: ApkAbi;
}
```

Functions to implement:
- `classifyApkAssetName(name: string): ApkAbi | null`
- `collectApkAssets(assets: ReleaseAsset[]): ClassifiedApkAsset[]`
- `recommendPrimaryAsset(assets: ClassifiedApkAsset[]): ClassifiedApkAsset | null`

`collectApkAssets(...)` maps a GitHub release asset into `{ name, url, abi }`.

Recommendation rule: prefer `arm64-v8a`, then `armeabi-v7a`, then `x86_64`. The card renders all available ABIs as alternatives regardless.

`isAndroidUserAgent` is no longer needed — remove it from the public surface and from the tests.

- [ ] **Step 2: Run the unit tests and make them pass before touching the homepage**

Run: `yarn --cwd site test`

Expected:
- PASS
- the helper behavior is locked before component work begins

- [ ] **Step 3: Create the build-time APK download card component**

Write `site/src/components/ApkDownloadCard.astro` that fetches release data at build time:

```astro
---
import { collectApkAssets, recommendPrimaryAsset } from ‘../lib/apk-release’;

const RELEASES_URL = ‘https://github.com/BigtoC/ledgerly/releases’;

let recommended: import(‘../lib/apk-release’).ClassifiedApkAsset | null = null;
let alternatives: import(‘../lib/apk-release’).ClassifiedApkAsset[] = [];
let releaseUrl = RELEASES_URL;
let checksumUrl: string | null = null;

try {
  const res = await fetch(‘https://api.github.com/repos/BigtoC/ledgerly/releases/latest’);
  if (res.ok) {
    const data = await res.json();
    releaseUrl = data.html_url ?? RELEASES_URL;
    const classified = collectApkAssets(data.assets ?? []);
    recommended = recommendPrimaryAsset(classified);
    alternatives = classified.filter(a => a !== recommended);
    const checksumAsset = (data.assets ?? []).find(
      (a: { name: string; browser_download_url: string }) => a.name.endsWith(‘-checksums.txt’)
    );
    checksumUrl = checksumAsset?.browser_download_url ?? null;
  }
} catch {
  // build-time fetch failed; fall back to static releases link
}
---
```

The component renders:
- If `recommended` is set: a primary download link (arm64-v8a) with the label "Download for Android (arm64 — most phones)" plus a SHA-256 checksum link if `checksumUrl` is available
- A secondary list of all alternative ABI links with "Other architectures" heading
- A note: "Not sure which to choose? Most modern Android phones use arm64-v8a."
- If `recommended` is null: a static fallback link to `releaseUrl` with text "Download from GitHub Releases"

No `<script>` tag. No client-side fetch. No loading state.

- [ ] **Step 4: Replace the temporary homepage CTA with the real component**

Update `site/src/pages/index.astro`:

```astro
---
import ApkDownloadCard from ‘../components/ApkDownloadCard.astro’;
import ScreenshotGallery from ‘../components/ScreenshotGallery.astro’;
---

<ApkDownloadCard />
```

Keep the guide CTA separate from the download card.

- [ ] **Step 5: Verify test, type, and build paths together**

Run: `yarn --cwd site test`

Expected: PASS

Run: `yarn --cwd site check`

Expected: PASS

Run: `yarn --cwd site build`

Expected: PASS — if no GitHub release exists yet, the card renders the static fallback link; this is correct behavior.

- [ ] **Step 6: Preview the homepage in a browser before committing**

Run: `yarn --cwd site preview`

Manual checks:
- if a GitHub Release exists, the card shows the recommended arm64-v8a download link and alternatives
- if no release exists, the card shows the static GitHub Releases fallback link
- the card is fully visible immediately (no loading spinner)
- the checksum link appears when `checksumUrl` is non-null

If browser automation is available, use `@test-browser` for this manual verification.

- [ ] **Step 7: Commit the download flow separately from workflow changes**

```bash
git add site/src/lib/apk-release.ts site/src/lib/apk-release.test.ts site/src/components/ApkDownloadCard.astro site/src/pages/index.astro
git commit -m "feat(site): add release-aware apk downloads"
```

### Task 7: Update Android release automation for split APK assets

**Files:**
- Modify: `.github/workflows/android-release.yml`

**Why this task exists:** The website depends on stable ABI-specific release asset names, and the current workflow only uploads one universal APK.

- [ ] **Step 1: Change the build step to produce split APKs**

Replace:

```yaml
- name: Build release APK
  run: flutter build apk --release
```

With:

```yaml
- name: Build split release APKs
  run: flutter build apk --release --split-per-abi
```

- [ ] **Step 2: Replace the single-file copy step with a deterministic rename loop**

Use a bash loop in `.github/workflows/android-release.yml`:

```yaml
- name: Prepare release assets
  shell: bash
  run: |
    if [[ ! "${GITHUB_REF_NAME}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "Unexpected ref name: ${GITHUB_REF_NAME}" >&2
      exit 1
    fi
    shopt -s nullglob
    files=(build/app/outputs/flutter-apk/app-*-release.apk)
    if [ ${#files[@]} -eq 0 ]; then
      echo "No split APKs found" >&2
      exit 1
    fi

    for file in "${files[@]}"; do
      base=$(basename "$file")
      abi="${base#app-}"
      abi="${abi%-release.apk}"
      cp "$file" "ledgerly-${GITHUB_REF_NAME}-${abi}.apk"
    done
```

- [ ] **Step 3: Generate a SHA-256 checksum manifest and upload all assets**

After the rename loop, generate the checksum file:

```yaml
- name: Generate checksums
  shell: bash
  run: sha256sum ledgerly-${GITHUB_REF_NAME}-*.apk > ledgerly-${GITHUB_REF_NAME}-checksums.txt
```

Then update the `softprops/action-gh-release` file input to include both APKs and the checksum manifest:

```yaml
with:
  files: |
    ledgerly-${{ github.ref_name }}-*.apk
    ledgerly-${{ github.ref_name }}-checksums.txt
```

- [ ] **Step 4: Rehearse the rename logic locally with fake filenames before relying on CI**

Run this from the repo root:

```bash
tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/build/app/outputs/flutter-apk" && \
touch "$tmpdir/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
      "$tmpdir/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
      "$tmpdir/build/app/outputs/flutter-apk/app-x86_64-release.apk" && \
GITHUB_REF_NAME=v0.1.0 bash -lc 'cd "$1" && shopt -s nullglob; files=(build/app/outputs/flutter-apk/app-*-release.apk); for file in "${files[@]}"; do base=$(basename "$file"); abi="${base#app-}"; abi="${abi%-release.apk}"; cp "$file" "ledgerly-${GITHUB_REF_NAME}-${abi}.apk"; done' bash "$tmpdir" && \
ls "$tmpdir"/ledgerly-v0.1.0-*.apk
```

Expected:
- at least one file printed matching `ledgerly-v0.1.0-*.apk` (exact ABI set depends on the NDK toolchain available; `arm64-v8a`, `armeabi-v7a`, and `x86_64` are typical)

- [ ] **Step 5: Commit the release-workflow change separately**

```bash
git add .github/workflows/android-release.yml
git commit -m "ci(release): publish split apk assets"
```

- [ ] **Step 6: Verify a tagged release uploads all expected assets in GitHub**

After the workflow is merged and a test tag is pushed, verify on the GitHub release page:
- at least one `ledgerly-<tag>-<abi>.apk` file is present
- `ledgerly-<tag>-checksums.txt` is present and contains SHA-256 lines for each APK

In the release notes for this first split-APK release, add a migration note: users who previously installed the universal APK should download the `arm64-v8a` variant (suitable for most modern Android phones); the universal APK is no longer published.

### Task 8: Add site validation, GitHub Pages deployment, and contributor docs

**Files:**
- Create: `.github/workflows/site-check.yml`
- Create: `.github/workflows/github-pages.yml`
- Modify: `README.md`

**Why this task exists:** The site needs its own validation path and deployment path without piggybacking on Flutter CI.

- [ ] **Step 1: Create a dedicated site-check workflow**

Write `.github/workflows/site-check.yml` that triggers on PRs and pushes affecting the site or its automation files:

```yaml
on:
  pull_request:
    paths:
      - 'site/**'
      - '.github/workflows/site-check.yml'
      - '.github/workflows/github-pages.yml'
      - '.github/workflows/android-release.yml'
      - 'README.md'
      - '.gitignore'
  push:
    branches: [main]
    paths:
      - 'site/**'
      - '.github/workflows/site-check.yml'
      - '.github/workflows/github-pages.yml'
      - '.github/workflows/android-release.yml'
      - 'README.md'
      - '.gitignore'
```

Its job should:
- checkout
- setup Node 22 using `actions/setup-node@v4` with `node-version: '22'`
- run `corepack enable`
- run `yarn --cwd site install --immutable`
- run `yarn --cwd site npm audit --severity high`
- run `yarn --cwd site test`
- run `yarn --cwd site check`
- run `yarn --cwd site build`

- [ ] **Step 2: Create the GitHub Pages deployment workflow using Astro’s official action**

Write `.github/workflows/github-pages.yml` using `withastro/action@v3` and `actions/deploy-pages@v4`.

Required details:
- trigger on `push` to `main`
- trigger on `workflow_run: workflows: ["Android release"], types: [completed]` — this creates an explicit dependency on `.github/workflows/android-release.yml` completing, so the Pages build always runs after the APK assets are uploaded; add a job-level condition `if: github.event_name != 'workflow_run' || github.event.workflow_run.conclusion == 'success'` so a failed Android release does not redeploy the site
- do **not** use `release: [published]` — `workflow_run` is more precise because it fires only when this specific workflow finishes, not when any release is manually published
- allow `workflow_dispatch`
- workflow-level default: `permissions: contents: read`; elevate `pages: write` and `id-token: write` at the deployment job level only (not at the top-level workflow block)
- Astro action `path: ./site`
- deployment job with environment `github-pages`
- pin both third-party actions to immutable commit SHAs (add the version tag as a comment); configure Dependabot `github-actions` ecosystem to receive automated SHA-bump PRs

- [ ] **Step 3: Update the repo README with site development commands**

Add a short `## Website` section to `README.md` with commands like:

```bash
corepack enable
yarn --cwd site install
yarn --cwd site dev
yarn --cwd site test
yarn --cwd site check
yarn --cwd site build
```

Also mention that GitHub Pages deploys from `.github/workflows/github-pages.yml` and that the public APK button reads the latest GitHub Release.

- [ ] **Step 4: Run the same commands the new `site-check` workflow will run**

Run:

```bash
corepack enable
yarn --cwd site install --immutable
yarn --cwd site test
yarn --cwd site check
yarn --cwd site build
```

Expected:
- all commands exit `0`
- local execution matches workflow expectations

- [ ] **Step 5: Verify the GitHub Pages workflow configuration is buildable in Actions**

After the workflow file is pushed to a branch, confirm in GitHub Actions that:
- the `github-pages` workflow starts
- the Astro build step completes successfully for `path: ./site`
- the deploy job receives a Pages artifact

If branch-scoped deploy is undesirable before merge, run the workflow with `workflow_dispatch` after merging and verify the same checkpoints.

- [ ] **Step 6: Commit the automation and README updates**

```bash
git add .github/workflows/site-check.yml .github/workflows/github-pages.yml README.md
git commit -m "ci(site): add validation and pages deploy"
```

### Task 9: Final verification and operator handoff

**Files:**
- Modify: none expected

**Why this task exists:** The plan is not done until both the website and the split-APK assumptions are verified end to end.

- [ ] **Step 1: Run the full local site verification suite one more time**

Run:

```bash
yarn --cwd site test
yarn --cwd site check
yarn --cwd site build
```

Expected:
- all exit `0`

- [ ] **Step 2: Verify the Flutter build still emits split APKs with the workflow’s expected names**

Run from the repo root:

```bash
flutter build apk --release --split-per-abi
```

Expected: at least one `app-*-release.apk` in `build/app/outputs/flutter-apk/`. The exact ABI set depends on the NDK toolchain; `arm64-v8a`, `armeabi-v7a`, and `x86_64` are typical but not guaranteed.

Also verify that a real tagged GitHub release uploaded the renamed assets listed in Task 7, Step 6.

- [ ] **Step 3: Smoke-test the built site in a browser**

Run: `yarn --cwd site preview`

Manual checks:
- homepage hero and screenshot gallery render
- `Read the Ledgerly Guide` opens the guide route
- download card handles success and fallback states
- pages load correctly under the `/ledgerly` base path

If browser automation is available, use `@test-browser` to click the guide link and inspect the download card state.

- [ ] **Step 4: Complete the GitHub Pages operator step**

In GitHub repository settings:
- open `Settings -> Pages`
- set **Source** to **GitHub Actions**

This is a manual repo-setting change, not a code change.

- [ ] **Step 5: Confirm the GitHub Pages deployment published successfully**

After the Pages workflow runs, verify in GitHub Actions and the Pages environment that:
- the deploy job finished successfully
- the environment URL resolves
- `https://bigtoc.github.io/ledgerly/` serves the homepage with the correct base path

If verification in steps 1–5 forced any code fixes, commit only the changed files: `git add <fixed-files> && git commit -m "fix(site): complete pages release flow"`.
