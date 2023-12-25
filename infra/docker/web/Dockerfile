FROM node:18-slim as base

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y build-essential openssl pkg-config python-is-python3 jq git  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives 


# ensure that both local and docker turbo are aligned on the package.json version.
RUN TURBO_VERSION=$(cat package.json | jq '.dependencies["turbo"]' -r) npm i -g turbo@${TURBO_VERSION}

#############################################
FROM base as builder


# Optimize for YARN installation speed
ENV YARN_ENABLE_GLOBAL_CACHE=false \
    YARN_ENABLE_MIRROR=false \
    YARN_NODE_LINKER=node-modules \
    YARN_NM_MODE=hardlinks-local


# Disabling some well-known postinstall scripts
ENV PRISMA_SKIP_POSTINSTALL_GENERATE=true \
    HUSKY=0


WORKDIR /app


ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG CALCOM_TELEMETRY_DISABLED
ARG DATABASE_URL
ARG NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
ARG NEXTAUTH_URL=${NEXT_PUBLIC_WEBAPP_URL}/api/auth 
ARG NEXTAUTH_SECRET=secret
ARG CALENDSO_ENCRYPTION_KEY=secret
ARG MAX_OLD_SPACE_SIZE=4096




ENV NODE_ENV=production \
    NEXT_PUBLIC_WEBAPP_URL=$NEXT_PUBLIC_WEBAPP_URL\
    NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    CALCOM_TELEMETRY_DISABLED=$CALCOM_TELEMETRY_DISABLED \
    DATABASE_URL=$DATABASE_URL \
    NEXTAUTH_SECRET=${NEXTAUTH_SECRET} \
    CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY} \
    NODE_OPTIONS=--max-old-space-size=${MAX_OLD_SPACE_SIZE} 
  
 
COPY --link  . .



RUN turbo prune --scope=@calcom/web --docker 


RUN yarn config set httpTimeout 1200000 && \ 
    yarn  

RUN  turbo run build --filter=@calcom/web... 

RUN rm -rf node_modules/.cache .yarn/cache apps/web/.next/cache
   

#############################################
FROM base as runner

WORKDIR /app

#  dependencies needed for prisma migration at runtime

RUN PRISMA_VERSION=$(cat packages/prisma/package.json | jq '.dependencies["prisma"]' -r) npm i prisma@${PRISMA_VERSION} && \
    TS_NODE_VERSION=$(cat packages/prisma/package.json | jq '.dependencies["ts-node"]' -r) npm i ts-node@${TS_NODE_VERSION} && \
    TYPESCRIPT_VERSION=$(cat package.json | jq '.devDependencies["typescript"]' -r) npm i typescript@${TYPESCRIPT_VERSION} 
     
    
   
COPY --from=builder --chown=node:node  /app/apps/web/next.config.js \
                    /app/apps/web/next-i18next.config.js \
                    /app/apps/web/package.json \
                    ./
             

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=node:node  /app/apps/web/.next/standalone ./
COPY --from=builder --chown=node:node  /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=node:node  /app/apps/web/public ./apps/web/public


COPY packages/prisma /app/packages/prisma

EXPOSE 3000

USER node

CMD [ "yarn", "workspace", "@calcom/web", "docker-start-web"]

