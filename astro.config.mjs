import { defineConfig } from 'astro/config';
import vue from "@astrojs/vue";
import deno from "@astrojs/deno";

// https://astro.build/config
export default defineConfig({
  integrations: [vue()],
  output: "server",
  adapter: deno()
});