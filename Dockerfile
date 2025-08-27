# --- Stage 1: Build the Astro site ---
FROM node:20-alpine AS build

WORKDIR /app
RUN corepack enable && corepack prepare pnpm@9.7.1 --activate

COPY package.json pnpm-lock.yaml* package-lock.json* yarn.lock* ./
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm install; fi

COPY . .
RUN npm run build

# --- Stage 2: Serve with NGINX ---
FROM nginx:1.27-alpine AS run
RUN apk add --no-cache curl
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/site.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -fsS http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
