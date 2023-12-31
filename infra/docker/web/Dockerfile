FROM node:18-slim as base

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y build-essential openssl pkg-config python-is-python3 jq git  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives 

#############################################
FROM base as builder

# Turbo needed for prunning before yarn installation
RUN TURBO_VERSION=$(cat package.json | jq '.dependencies["turbo"]' -r) npm i -g turbo@${TURBO_VERSION}

# Optimizes for YARN installation speed
ENV YARN_ENABLE_GLOBAL_CACHE=false \
    YARN_ENABLE_MIRROR=false \
    YARN_NODE_LINKER=node-modules \
    YARN_NM_MODE=hardlinks-local


# Disables some well-known postinstall scripts
ENV PRISMA_SKIP_POSTINSTALL_GENERATE=true \
    HUSKY=0


WORKDIR /app

ENV NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000 \
    NEXTAUTH_URL=http://localhost:3000/api/auth \
    NEXTAUTH_SECRET=secret \
    CALENDSO_ENCRYPTION_KEY=secret \
    NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    CALCOM_TELEMETRY_DISABLED=$CALCOM_TELEMETRY_DISABLED \
    MAX_OLD_SPACE_SIZE=4096 

ENV NODE_ENV=production \
    NODE_OPTIONS=--max-old-space-size=${MAX_OLD_SPACE_SIZE}  


COPY --link  . .

RUN turbo prune --scope=@calcom/web --docker && \
    yarn config set httpTimeout 1200000 && \ 
    yarn && \
    turbo run build --filter=@calcom/web... && \
    rm -rf node_modules/.cache .yarn/cache apps/web/.next/cache


# #############################################
FROM base as unit-test

WORKDIR /app

COPY --from=builder /app/. ./

RUN yarn test 

#############################################
FROM node:18-slim as runner

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y openssl jq curl bash && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app

# prisma schema to be loaded at runtime
RUN PRISMA_VERSION=$(cat packages/prisma/package.json | jq '.dependencies["prisma"]' -r) npm i prisma@${PRISMA_VERSION} 
COPY --from=builder --chown=node:node /app/packages/prisma/schema.prisma /app/packages/prisma/schema.prisma

COPY --from=builder --chown=node:node  /app/apps/web/next.config.js \
                    /app/apps/web/next-i18next.config.js \
                    /app/apps/web/package.json \
                    ./

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=node:node  /app/apps/web/.next/standalone ./
COPY --from=builder --chown=node:node  /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=node:node  /app/apps/web/public ./apps/web/public

# Replaces needed statically built envs with run-time env
COPY --chown=node:node infra/docker/web/entrypoint.sh ./entrypoint.sh
COPY --chown=node:node placeholder.yml ./placeholder.yml
RUN ["chmod", "+x", "./entrypoint.sh"]

USER node

ENTRYPOINT ["./entrypoint.sh"]

CMD ["yarn", "workspace", "@calcom/web", "docker-start-web"]


      
