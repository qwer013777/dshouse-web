import { defineCollection, z } from "astro:content";

const works = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    date: z.string().transform((s) => new Date(s)),
    summary: z.string().optional(),
  }),
});

export const collections = { works };
