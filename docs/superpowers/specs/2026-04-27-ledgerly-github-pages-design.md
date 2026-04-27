# Ledgerly GitHub Pages Design

## Context

Ledgerly needs a public GitHub Pages site for end users. The site should explain
the app, present a friendly guide derived from the README user handbook, show
real app screenshots, and provide Android APK downloads from the latest GitHub
Release.

The app is Android-first, local-first, and MVP-focused. It does not require
sign-in, bank sync, or cloud setup. The existing release workflow already builds
and uploads an Android APK on tag pushes, but the release assets should be split
per ABI to reduce download size.

## Goals

- Create an end-user site at GitHub Project Pages:
  `https://bigtoc.github.io/ledgerly/`.
- Use Astro with Starlight, plus a custom product homepage.
- Explain Ledgerly's product promise and MVP boundaries clearly.
- Include a `Ledgerly Guide` section based on the README user handbook.
- Show a screenshot tour using real app screenshots.
- Download the latest split Android APK from GitHub Releases.
- Recommend the best APK when possible while still showing manual alternatives.

## Non-Goals

- Do not build a contributor-focused documentation site in the first version.
- Do not publish iOS, desktop, or web app downloads in the first version.
- Do not add cloud install, app-store distribution, or update infrastructure.
- Do not run Flutter app tests for site-only edits unless shared repo config is
  changed.

## Recommended Approach

Use Starlight with a custom homepage.

Starlight gives the site a strong documentation foundation: markdown content,
navigation, search, dark mode, metadata, and accessibility defaults. A custom
Astro homepage keeps the first impression product-focused instead of docs-first.
This combination supports the landing page, user guide, screenshots, and release
download button without building a bespoke static site framework.

## Site Architecture

Add a small Astro/Starlight project inside the existing repository, likely under
`site/`, so the Flutter app structure remains untouched. The site build should
configure Astro for GitHub Project Pages with:

- `site: "https://bigtoc.github.io"`
- `base: "/ledgerly"`

The GitHub Pages workflow should be separate from Flutter CI and Android release
automation. It should install the site dependencies, build the static output,
and publish the generated artifact to GitHub Pages.

The current `.superpowers/` visual brainstorming output is local working data and
should not be committed. If visual companion files are kept in the repo during
future design sessions, `.superpowers/` should be ignored before committing.

## Page Structure

### Homepage

The homepage should be a product landing page for end users. It should include:

- Hero section with the promise: private expense tracking in a few taps.
- Primary CTA: `Download Android APK`.
- Secondary CTA: `Read the Ledgerly Guide`.
- Core benefits: local-first, fast manual entry, seeded defaults, multiple
  accounts, expense and income tracking, no sign-in.
- Real screenshots tour covering the main flows: Splash, Home, Add/Edit
  Transaction, Accounts or Categories, and Settings.
- Privacy/local-first promise explaining that MVP data stays on-device.
- Simple usage flow: open app, add transaction, choose account/category, save,
  review on Home.
- MVP limitations: no bank sync, cloud backup, budgets, charts, recurring
  automation, or crypto wallet sync yet.
- Android install note explaining that users may need to allow APK installs from
  the browser or GitHub.

### Ledgerly Guide

Use `Ledgerly Guide` as the public handbook name. The guide should adapt the
README user handbook into Starlight pages such as:

- Getting Started
- Main Screens
- Daily Usage
- MVP Limitations

Contributor commands, architecture guardrails, and internal development notes
should stay out of the end-user guide unless a separate developer section is
added later.

## Android Release Workflow

Update `.github/workflows/android-release.yml` to build split APKs:

```bash
flutter build apk --release --split-per-abi
```

Flutter should produce separate APKs for the supported ABIs, commonly:

- `app-arm64-v8a-release.apk`
- `app-armeabi-v7a-release.apk`
- `app-x86_64-release.apk`

The workflow should rename and upload each APK with a stable convention:

```text
ledgerly-<tag>-arm64-v8a.apk
ledgerly-<tag>-armeabi-v7a.apk
ledgerly-<tag>-x86_64.apk
```

The site depends on this naming convention to classify release assets. The first
version should upload split APKs only, not a universal APK fallback.

## Download Component

The homepage should include a small client-side download component that:

1. Fetches `https://api.github.com/repos/BigtoC/ledgerly/releases/latest`.
2. Reads the latest release assets.
3. Filters `.apk` assets.
4. Classifies APKs by ABI from filename.
5. Recommends one APK and shows manual alternatives.

Browser JavaScript cannot reliably detect an Android device's exact CPU ABI.
The component should therefore avoid claiming certainty. For Android browsers,
it should recommend `arm64-v8a` by default because most modern Android phones use
64-bit ARM. It should also show:

- `armeabi-v7a` for older 32-bit Android devices.
- `x86_64` for Android emulators or rare Intel devices.

For non-Android browsers, the component should say that Android APKs are
available and list the same choices. Once APK assets are found, users should be
able to download any available ABI manually.

## Error Handling

The download component should handle these states explicitly:

- Loading latest release.
- Ready with recommended APK and alternatives.
- No APK assets found in the latest release.
- GitHub API unavailable or rate-limited.
- Unknown platform or uncertain ABI.

If the API is unavailable or no suitable APK is found, the CTA should fall back
to the GitHub Releases page, preferably the latest release URL when available or
`https://github.com/BigtoC/ledgerly/releases` otherwise.

## Testing And Verification

- Run the Astro/Starlight build for site changes.
- Add focused tests for release asset classification and ABI recommendation if
  the logic is extracted into a helper module.
- Verify the GitHub Pages workflow builds and publishes the static artifact.
- Verify the Android release workflow uploads all expected split APK filenames
  after a tagged release.
- Run Flutter verification only if changes touch Flutter app code, shared repo
  config, or existing Flutter workflows.

## Open Decisions For Implementation Planning

- Exact `site/` package scripts and package manager choice.
- Screenshot capture workflow and image dimensions.
- Whether the `Ledgerly Guide` starts as one page or multiple Starlight pages.
- Whether to add a small FAQ in the first site version or defer it.
