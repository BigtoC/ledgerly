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
