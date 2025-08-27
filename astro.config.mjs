// astro.config.mjs
import { defineConfig } from 'astro/config';
import tailwind from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://www.dshouse.co.kr',
  integrations: [sitemap()],
  vite: { plugins: [tailwind()] },
});
