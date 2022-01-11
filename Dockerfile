from node:16-alpine
# version arg contains current git tag
ARG VERSION_ARG
# install git
RUN apk update
RUN apk add --no-cache git

# install mango-bowl globally (exposes mango-bowl command)
RUN npm install --global --unsafe-perm mango-bowl@$VERSION_ARG
# run it
CMD mango-bowl