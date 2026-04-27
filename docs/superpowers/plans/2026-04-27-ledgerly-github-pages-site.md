# Ledgerly GitHub Pages Site Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Starlight-based GitHub Pages site for Ledgerly with a custom landing page, README-derived `Ledgerly Guide`, real screenshots, and a latest-release split-APK download flow while updating Android release automation to publish ABI-specific assets.

**Architecture:** Keep the Flutter app and the website isolated by adding a dedicated `site/` Astro workspace inside the repo. Use Starlight for guide content and navigation, a custom Astro homepage for the marketing surface, and a small pure TypeScript helper to classify GitHub release assets so the interactive download card stays testable and the DOM code stays thin.

**Tech Stack:** Astro, Starlight, TypeScript, plain CSS, Vitest, GitHub Actions, existing Flutter Android build pipeline.

---

## Locked Decisions

- Use a dedicated `site/` workspace instead of mixing Node files into the Flutter root.
- Use `npm` with a committed `site/package-lock.json` so `withastro/action` can auto-detect the package manager.
- Use Starlight + custom CSS only. Do not add Tailwind unless the homepage styling proves blocked without it.
- Put the public guide under `site/src/content/docs/ledgerly-guide/` as four Markdown pages.
- Keep Flutter CI unchanged; add dedicated site validation and Pages deployment workflows instead of forcing Node work into `.github/workflows/ci.yml`.
- Update Android release automation to publish split APKs only, using predictable filenames that the site can parse.

## References To Keep Open

- Spec: `docs/superpowers/specs/2026-04-27-ledgerly-github-pages-design.md`
- Source content: `README.md` (`## User handbook`, status text, MVP limitations)
- Existing release workflow: `.github/workflows/android-release.yml`
- Astro GitHub Pages guide: `https://docs.astro.build/en/guides/deploy/github/`
- Starlight guides: `https://starlight.astro.build/guides/pages/`, `https://starlight.astro.build/guides/sidebar/`, `https://starlight.astro.build/guides/project-structure/`

## File Map

- Modify: `.gitignore` — ignore `site/` build artifacts and local Node output.
- Modify: `.github/workflows/android-release.yml` — build split APKs, rename them deterministically, upload all assets.
- Modify: `README.md` — add contributor-facing website commands and deployment notes.
- Create: `.github/workflows/site-check.yml` — validate the site on PRs and relevant pushes.
- Create: `.github/workflows/github-pages.yml` — build and deploy `site/` to GitHub Pages.
- Create: `site/package.json` — Node scripts and dependencies.
- Create: `site/package-lock.json` — committed lockfile for CI and Pages builds.
- Create: `site/tsconfig.json` — strict Astro TypeScript config.
- Create: `site/astro.config.mjs` — `site`, `base`, Starlight integration, sidebar, custom CSS.
- Create: `site/src/content.config.ts` — Starlight content collection config.
- Create: `site/src/styles/custom.css` — Starlight theme variables and homepage styles.
- Create: `site/src/pages/index.astro` — custom product homepage.
- Create: `site/src/components/ScreenshotGallery.astro` — display real app screenshots with captions.
- Create: `site/src/components/ApkDownloadCard.astro` — interactive download UI shell.
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
- Create: `site/package-lock.json`

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

- [ ] **Step 4: Install the site dependencies and generate the lockfile**

Run: `npm --prefix site install`

Expected:
- command exits `0`
- `site/package-lock.json` is created
- `site/node_modules/` is populated locally

- [ ] **Step 5: Sanity-check the installed Astro CLI before adding app code**

Run: `npm --prefix site exec astro --version`

Expected:
- command exits `0`
- prints an Astro version string

- [ ] **Step 6: Commit the bootstrap-only change**

```bash
git add .gitignore site/package.json site/package-lock.json site/tsconfig.json
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
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/BigtoC/ledgerly'
        }
      ]
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

Run: `npm --prefix site run check`

Expected:
- exits `0`
- no Starlight content-schema errors

Run: `npm --prefix site run build`

Expected:
- exits `0`
- `site/dist/index.html` exists
- `site/dist/ledgerly-guide/getting-started/index.html` exists

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

Run: `npm --prefix site run check`

Expected:
- exits `0`
- no missing sidebar slug errors

Run: `npm --prefix site run build`

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

Capture all five screenshots in portrait orientation from the same Android phone-sized viewport. Keep the system status bar visible, use the app's actual light-or-dark theme consistently across all screenshots, and avoid mixing tablet and phone captures in the same gallery.

If Android emulator tooling is available, capture with `adb exec-out screencap -p > <target-file>` after navigating to each screen. If not, use the simulator/device screenshot tool and save each PNG to the exact path above.

- [ ] **Step 2: Create a dedicated screenshot gallery component**

Write `site/src/components/ScreenshotGallery.astro` using `astro:assets` so the homepage stays focused on layout, not image plumbing.

The component should render a list of screenshot cards with:
- image
- screen name
- one-sentence caption
- meaningful `alt` text

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
- hero with app promise
- static primary CTA placeholder linking to GitHub Releases for now
- secondary CTA to `./ledgerly-guide/getting-started/`
- benefits grid
- `ScreenshotGallery`
- privacy/local-first promise
- simple “how it works” steps
- MVP limitations summary
- Android install note

Use `StarlightPage` with `hasSidebar={false}` so the page inherits Starlight theme/header behavior while remaining custom.

- [ ] **Step 4: Extend `custom.css` only as far as the homepage needs**

Add homepage selectors for:
- two-column hero on wide screens
- card grid for benefits and screenshots
- readable spacing on mobile
- button and note styles that remain accessible in light and dark themes

Do not introduce a second global stylesheet.

- [ ] **Step 5: Run the site build and a manual local preview**

Run: `npm --prefix site run build`

Expected:
- exits `0`
- homepage and guide pages emit successfully

Run: `npm --prefix site run dev`

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
  isAndroidUserAgent,
} from './apk-release';

describe('classifyApkAssetName', () => {
  it('detects arm64-v8a assets from release filenames', () => {
    expect(classifyApkAssetName('ledgerly-v1.0.0-arm64-v8a.apk')).toBe('arm64-v8a');
  });
});
```

Add coverage for:
- `armeabi-v7a`
- `x86_64`
- ignoring non-APK assets
- preferring `arm64-v8a`
- falling back to first available APK when the preferred ABI is missing
- Android vs non-Android user-agent detection

- [ ] **Step 2: Run the test suite before implementing the helper**

Run: `npm --prefix site run test`

Expected:
- FAIL
- error mentions missing `./apk-release` exports or module not found

### Task 6: Implement the release helper and interactive APK download card

**Files:**
- Create: `site/src/lib/apk-release.ts`
- Create: `site/src/components/ApkDownloadCard.astro`
- Modify: `site/src/pages/index.astro`

**Why this task exists:** The homepage needs a resilient download flow that prefers the right split APK without pretending browser ABI detection is exact.

- [ ] **Step 1: Implement the pure helper module to keep DOM code thin**

Write `site/src/lib/apk-release.ts` with a focused API surface:

```ts
export type ApkAbi = 'arm64-v8a' | 'armeabi-v7a' | 'x86_64';

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
- `isAndroidUserAgent(userAgent: string): boolean`
- `classifyApkAssetName(name: string): ApkAbi | null`
- `collectApkAssets(assets: ReleaseAsset[]): ClassifiedApkAsset[]`
- `recommendPrimaryAsset(assets: ClassifiedApkAsset[], userAgent: string): ClassifiedApkAsset | null`

`collectApkAssets(...)` should be the function that maps a GitHub release asset into `{ name, url, abi }` by combining `browser_download_url` with the ABI returned from `classifyApkAssetName(...)`.

Recommendation rule:
- if Android or platform unknown, prefer `arm64-v8a`
- then `armeabi-v7a`
- then `x86_64`

- [ ] **Step 2: Run the unit tests and make them pass before touching the homepage**

Run: `npm --prefix site run test`

Expected:
- PASS
- the helper behavior is now locked before DOM rendering begins

- [ ] **Step 3: Create the interactive download card component**

Write `site/src/components/ApkDownloadCard.astro` with:
- a server-rendered fallback link to `https://github.com/BigtoC/ledgerly/releases`
- client-side fetch to `https://api.github.com/repos/BigtoC/ledgerly/releases/latest`
- DOM states for loading, ready, no assets, API failure, and unknown platform / uncertain ABI guidance
- one recommended APK plus manual alternatives
- copy that avoids claiming exact chip detection
- a preferred fallback to the latest release HTML URL when the API payload provides it, falling back to `https://github.com/BigtoC/ledgerly/releases` only when the latest release URL cannot be derived

The component’s client script should import the pure helper and keep network/DOM work in the component only.

- [ ] **Step 4: Replace the temporary homepage CTA with the real component**

Update `site/src/pages/index.astro`:

```astro
---
import ApkDownloadCard from '../components/ApkDownloadCard.astro';
import ScreenshotGallery from '../components/ScreenshotGallery.astro';
---

<ApkDownloadCard />
```

Keep the guide CTA separate from the download card.

- [ ] **Step 5: Verify test, type, and build paths together**

Run: `npm --prefix site run test`

Expected: PASS

Run: `npm --prefix site run check`

Expected: PASS

Run: `npm --prefix site run build`

Expected: PASS

- [ ] **Step 6: Preview the homepage in a browser before committing**

Run: `npm --prefix site run dev`

Manual checks:
- the page initially shows a loading state
- on success it shows a recommended APK and ABI alternatives
- on a forced network failure it falls back to GitHub Releases copy
- on non-Android or ambiguous platform strings it shows the uncertain-ABI guidance copy instead of claiming a chip match

Force the failure state by using browser DevTools offline mode or blocking `https://api.github.com` for the page session.

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
  run: |
    shopt -s nullglob
    files=(build/app/outputs/flutter-apk/app-*-release.apk)
    if [ ${#files[@]} -eq 0 ]; then
      echo "No split APKs found" >&2
      exit 1
    fi

    for file in "${files[@]}"; do
      abi="${file##*app-}"
      abi="${abi%-release.apk}"
      cp "$file" "ledgerly-${GITHUB_REF_NAME}-${abi}.apk"
    done
```

- [ ] **Step 3: Upload every renamed asset, not just one file**

Replace the `softprops/action-gh-release` file input with:

```yaml
with:
  files: ledgerly-${{ github.ref_name }}-*.apk
```

- [ ] **Step 4: Rehearse the rename logic locally with fake filenames before relying on CI**

Run this from the repo root:

```bash
tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/build/app/outputs/flutter-apk" && \
touch "$tmpdir/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
      "$tmpdir/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
      "$tmpdir/build/app/outputs/flutter-apk/app-x86_64-release.apk" && \
GITHUB_REF_NAME=v0.1.0 bash -lc 'cd "$1" && shopt -s nullglob; files=(build/app/outputs/flutter-apk/app-*-release.apk); for file in "${files[@]}"; do abi="${file##*app-}"; abi="${abi%-release.apk}"; cp "$file" "ledgerly-${GITHUB_REF_NAME}-${abi}.apk"; done' bash "$tmpdir" && \
ls "$tmpdir"/ledgerly-v0.1.0-*.apk
```

Expected:
- three files printed:
  - `ledgerly-v0.1.0-arm64-v8a.apk`
  - `ledgerly-v0.1.0-armeabi-v7a.apk`
  - `ledgerly-v0.1.0-x86_64.apk`

- [ ] **Step 5: Commit the release-workflow change separately**

```bash
git add .github/workflows/android-release.yml
git commit -m "ci(release): publish split apk assets"
```

- [ ] **Step 6: Verify a tagged release uploads all expected split APK assets in GitHub**

After the workflow is merged and a test tag is pushed, verify on the GitHub release page that the release contains all three ABI-specific files:
- `ledgerly-<tag>-arm64-v8a.apk`
- `ledgerly-<tag>-armeabi-v7a.apk`
- `ledgerly-<tag>-x86_64.apk`

Record this as operator evidence in the PR description or release notes because the site depends on those exact asset names.

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
- setup Node 22
- run `npm --prefix site ci`
- run `npm --prefix site run test`
- run `npm --prefix site run check`
- run `npm --prefix site run build`

- [ ] **Step 2: Create the GitHub Pages deployment workflow using Astro’s official action**

Write `.github/workflows/github-pages.yml` using `withastro/action@v6` and `actions/deploy-pages@v5`.

Required details:
- trigger on `push` to `main`
- allow `workflow_dispatch`
- permissions: `contents: read`, `pages: write`, `id-token: write`
- Astro action `path: ./site`
- deployment job with environment `github-pages`

- [ ] **Step 3: Update the repo README with site development commands**

Add a short `## Website` section to `README.md` with commands like:

```bash
npm --prefix site install
npm --prefix site run dev
npm --prefix site run test
npm --prefix site run check
npm --prefix site run build
```

Also mention that GitHub Project Pages deploys from `.github/workflows/github-pages.yml` and that the public APK button reads the latest GitHub Release.

- [ ] **Step 4: Run the same commands the new `site-check` workflow will run**

Run:

```bash
npm --prefix site ci
npm --prefix site run test
npm --prefix site run check
npm --prefix site run build
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
npm --prefix site run test
npm --prefix site run check
npm --prefix site run build
```

Expected:
- all exit `0`

- [ ] **Step 2: Verify the Flutter build still emits split APKs with the workflow’s expected names**

Run from the repo root:

```bash
flutter build apk --release --split-per-abi
```

Expected artifacts in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk`
- `app-armeabi-v7a-release.apk`
- `app-x86_64-release.apk`

Also verify that a real tagged GitHub release uploaded the renamed assets listed in Task 7, Step 6.

- [ ] **Step 3: Smoke-test the built site in a browser**

Run: `npm --prefix site run preview`

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

- [ ] **Step 6: Create the final verification commit if Task 9 required code edits**

If verification forced fixes, commit only the fix files:

```bash
git add <fixed-files>
git commit -m "fix(site): complete pages release flow"
```

If no files changed during verification, skip this step.
