import { defineConfig } from 'astro/config';
import vue from "@astrojs/vue";
import { astroImageTools } from "astro-imagetools";

// https://astro.build/config
export default defineConfig({
  integrations: [vue(), astroImageTools],
  site: 'https://christ-offer.github.io',
});