FROM node:18-slim as base

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y build-essential openssl pkg-config python-is-python3 jq git  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives 

#############################################
FROM base as builder

# ensure that both local and docker turbo are aligned on the package.json version.
RUN TURBO_VERSION=$(cat package.json | jq '.dependencies["turbo"]' -r) npm i -g turbo@${TURBO_VERSION}

# Optimize for YARN installation speed
ENV YARN_ENABLE_GLOBAL_CACHE=false \
    YARN_ENABLE_MIRROR=false \
    YARN_NODE_LINKER=node-modules \
    YARN_NM_MODE=hardlinks-local


# Disabling some well-known postinstall scripts
ENV PRISMA_SKIP_POSTINSTALL_GENERATE=true \
    HUSKY=0


WORKDIR /app

ARG NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000 \
    NEXTAUTH_SECRET=secret \
    CALENDSO_ENCRYPTION_KEY=secret \
    MAX_OLD_SPACE_SIZE=4096 

ENV NODE_ENV=production \
    NODE_OPTIONS=--max-old-space-size=${MAX_OLD_SPACE_SIZE}  


COPY --link  . .

RUN turbo prune --scope=@calcom/web --docker \
    yarn config set httpTimeout 1200000 && \ 
    yarn \
    turbo run build --filter=@calcom/web... \
    rm -rf node_modules/.cache .yarn/cache apps/web/.next/cache

#############################################
FROM node:18-slim as runner

WORKDIR /app

ENV NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    CALCOM_TELEMETRY_DISABLED=$CALCOM_TELEMETRY_DISABLED \
    NEXT_PUBLIC_WEBAPP_URL=$NEXT_PUBLIC_WEBAPP_URL\
    NEXTAUTH_SECRET=$NEXTAUTH_SECRET \
    CALENDSO_ENCRYPTION_KEY=$CALENDSO_ENCRYPTION_KEY
    

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y openssl curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives


RUN ["chmod", "+x", "/infra/docker/web/entrypoint.sh"]

# dependency needed for prisma migration at runtime
RUN PRISMA_VERSION=$(cat packages/prisma/package.json | jq '.dependencies["prisma"]' -r) npm i prisma@${PRISMA_VERSION} 


# chown to node default user/group
COPY --from=builder --chown=node:node  /app/apps/web/next.config.js \
                    /app/apps/web/next-i18next.config.js \
                    /app/apps/web/package.json \
                    ./



# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=node:node  /app/apps/web/.next/standalone ./
COPY --from=builder --chown=node:node  /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=node:node  /app/apps/web/public ./apps/web/public


# prisma schema to be loaded at runtime
COPY --from=builder --chown=node:node /app/packages/prisma/schema.prisma /app/packages/prisma/schema.prisma

EXPOSE 3000

USER node

ENTRYPOINT ["/app/entrypoint.sh"]

CMD [ "yarn", "workspace", "@calcom/web", "docker-start-web"]

