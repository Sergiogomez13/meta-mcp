# ---------- Base stage ----------
FROM node:18-bullseye-slim AS base

# Instala dumb-init para gestionar correctamente las señales
RUN apt-get update \
  && apt-get install -y --no-install-recommends dumb-init \
  && rm -rf /var/lib/apt/lists/*

# Crea directorio de trabajo
WORKDIR /app

# Copia package.json + package-lock.json / pnpm-lock / yarn.lock
COPY package*.json ./

# Instala solo dependencias de producción
RUN npm ci --only=production && npm cache clean --force


# ---------- Build stage ----------
FROM node:18-bullseye-slim AS build

WORKDIR /app

# Copia manifest y tsconfig
COPY package*.json ./
COPY tsconfig.json ./

# Instala TODAS las dependencias (incluidas dev) para compilar
RUN npm ci

# Copia el código fuente
COPY src/ ./src/

# Compila TypeScript → build/
RUN npm run build


# ---------- Production stage ----------
FROM base AS production

# Copia el resultado de la compilación
COPY --from=build /app/build ./build


# Crea usuario no root
RUN groupadd -g 1001 nodejs \
  && useradd -u 1001 -g nodejs -s /bin/sh -m nodejs \
  && chown -R nodejs:nodejs /app
USER nodejs

# Puerto opcional (útil para health-checks)
EXPOSE 3000

ENV NODE_ENV=production

# Healthcheck sencillo (opcional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node build/index.js --version || exit 1

# Usa dumb-init como init system
ENTRYPOINT ["dumb-init", "--"]

# Comando por defecto
CMD ["node", "build/index.js"]
