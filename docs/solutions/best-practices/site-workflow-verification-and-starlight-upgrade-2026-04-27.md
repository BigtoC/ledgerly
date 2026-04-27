---
title: Site workflow verification and Starlight upgrade for GitHub Pages
date: 2026-04-27
category: best-practices
module: github-pages-site
problem_type: best_practice
component: tooling
severity: medium
applies_when:
  - Adding or maintaining the repo-local Astro site under site/
  - Verifying GitHub Actions commands locally before claiming the site workflow is green
  - Upgrading Astro or Starlight to satisfy security or workflow audit requirements
tags:
  - astro
  - starlight
  - github-pages
  - yarn
  - corepack
  - workflows
  - static-site
---

# Site workflow verification and Starlight upgrade for GitHub Pages

## Context

The Ledgerly GitHub Pages site introduced a separate `site/` Node workspace with its own CI and deployment workflows. Two easy-to-miss issues surfaced while validating that setup: running the package-manager install concurrently with `test`/`check`/`build` produced false missing-module failures, and the original Astro 5 plus Starlight 0.30 stack failed the security-gated dependency audit because Astro 5 is covered by a high-severity advisory.

## Guidance

Verify the site workflow commands sequentially from a clean install, matching the workflow order.

Do not run `yarn --cwd site install --immutable` in parallel with `yarn --cwd site test`, `yarn --cwd site check`, or `yarn --cwd site build`. A clean install rewrites `site/node_modules`, so parallel execution can produce transient `MODULE_NOT_FOUND` errors that do not reflect a real lockfile problem.

Use the same command order as the workflow:

```bash
corepack enable && \
  yarn --cwd site install --immutable && \
  yarn --cwd site npm audit --severity high && \
  yarn --cwd site test && \
  yarn --cwd site check && \
  yarn --cwd site build
```

Keep the APK card fallback pointed at the repository releases index, not the latest release page.

When the latest-release fetch succeeds but the release assets do not include recognized split APK names, the homepage should still send users to `https://github.com/BigtoC/ledgerly/releases`. Falling back to a single release page makes a malformed or incomplete release look authoritative.

When the site workflow includes a package audit gate, treat security-driven dependency upgrades as part of workflow correctness, not optional maintenance.

For Ledgerly's site, the minimal working move was:

- upgrade `astro` from the Astro 5 line to `^6.1.9`
- upgrade `@astrojs/starlight` from `^0.30.0` to `^0.38.4`
- regenerate the committed site lockfile
- update Starlight config to the newer `social` array shape

```js
social: [
  {
    icon: 'github',
    label: 'GitHub',
    href: 'https://github.com/BigtoC/ledgerly',
  },
],
```

## Why This Matters

This keeps the local verification path aligned with CI instead of validating against a warm `node_modules/` tree or an obsolete dependency graph.

- Sequential verification avoids chasing fake missing-package failures caused by a package install racing with runtime commands.
- The audit gate only has value if the committed dependency range can actually pass it from a clean lockfile.
- Starlight config migrations are easy to miss during version bumps; baking them into the upgrade guidance prevents a dependency fix from turning into a runtime/config regression.
- The releases-index fallback preserves a safe download path even when the latest tagged release is incomplete or mispackaged.

## When to Apply

- A new workflow uses a clean package-manager install and additional Node-based checks.
- Local verification succeeds only when using an already-populated `node_modules/` tree.
- The package audit step fails for framework-level advisories.
- A Starlight upgrade starts failing in config parsing after dependency updates.
- A release-aware download component needs a resilient fallback path.

## Examples

- Correct local verification path for the Ledgerly site:

```bash
corepack enable
yarn --cwd site install --immutable
yarn --cwd site npm audit --severity high
yarn --cwd site test
yarn --cwd site check
yarn --cwd site build
```

- Correct release-card fallback:

```astro
<a class="apk-download-card__primary" href={RELEASES_URL}>
  Download from GitHub Releases
</a>
```

- Starlight 0.38-compatible social links:

```js
social: [
  {
    icon: 'github',
    label: 'GitHub',
    href: 'https://github.com/BigtoC/ledgerly',
  },
],
```

## Related

- `site/package.json` and `site/yarn.lock` — the audited dependency surface for the site workspace
- `.github/workflows/site-check.yml` — workflow command order to mirror locally
- `site/src/components/ApkDownloadCard.astro` — static latest-release fetch and fallback behavior
