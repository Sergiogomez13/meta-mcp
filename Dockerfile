# ---------- Build stage ----------
FROM node:20-bullseye-slim AS build

WORKDIR /app

# Copiamos TODO el proyecto de una vez,
# de modo que el script `prepare` (si se ejecuta) ya vea /src
COPY . .

# Instalamos dependencias y compilamos TypeScript
RUN npm ci && npm run build


# ---------- Production stage ----------
FROM node:20-bullseye-slim AS production

WORKDIR /app

# Copiamos TODO lo construido (código JS + node_modules)
COPY --from=build /app /app

# Instalamos dependencias de runtime (sin scripts ni dev-deps)
ENV NPM_CONFIG_IGNORE_SCRIPTS=true
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force

EXPOSE 3000
CMD ["node", "index.js"]


CMD ["node", "build/index.js"]

