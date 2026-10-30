import { describe, expect, it } from 'vitest';

import config from '../../astro.config.mjs';

// GitHub Pages serves the site from the ledgerlylab.com custom domain at the
// root, so a sub-path base makes every stylesheet, script and image 404.
describe('astro config', () => {
  it('targets the custom domain', () => {
    expect(config.site).toBe('https://ledgerlylab.com');
  });

  it('serves from the domain root', () => {
    expect(config.base ?? '/').toBe('/');
  });
});
