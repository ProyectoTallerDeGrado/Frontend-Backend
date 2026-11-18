# Imagen de la web (Next.js en modo `standalone`).
#   docker build -t emprendeu-web --build-arg SITE_URL=https://mi-dominio .
# En ejecución: API_URL (backend, siempre con /api/v1) y SITE_URL.
FROM node:22-alpine AS deps
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

FROM node:22-alpine AS build
WORKDIR /app
RUN corepack enable
ENV NEXT_TELEMETRY_DISABLED=1
# SITE_URL se usa al compilar (Open Graph, robots.txt, sitemap.xml).
ARG SITE_URL=http://localhost:3000
ENV SITE_URL=$SITE_URL
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

FROM node:22-alpine AS run
WORKDIR /app
# Vincula el paquete de GHCR con el repositorio (permite descargarlo con el GITHUB_TOKEN).
LABEL org.opencontainers.image.source="https://github.com/ProyectoTallerDeGrado/Frontend-Backend"
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0
RUN addgroup -S app && adduser -S -G app -u 10001 app
COPY --from=build --chown=app:app /app/.next/standalone ./
COPY --from=build --chown=app:app /app/.next/static ./.next/static
COPY --from=build --chown=app:app /app/public ./public
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:3000/ || exit 1
CMD ["node", "server.js"]
