import { defineConfig } from 'astro/config';
import vue from "@astrojs/vue";
import Chart from 'chart.js/auto';

import deno from "@astrojs/deno";

// https://astro.build/config
export default defineConfig({
  integrations: [vue()],
  site: 'https://christ-offer.github.io',
  markdown: {
    shikiConfig: {
      // Choose from Shiki's built-in themes (or add your own)
      // https://github.com/shikijs/shiki/blob/main/docs/themes.md
      theme: 'dracula',
      // Add custom languages
      // Note: Shiki has countless langs built-in, including .astro!
      // https://github.com/shikijs/shiki/blob/main/docs/languages.md
      // langs: [],
      // Enable word wrap to prevent horizontal scrolling
      wrap: true
    }
  },
  output: "server",
  adapter: deno()
});