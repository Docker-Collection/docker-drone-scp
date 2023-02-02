# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:66ffe58bd25bf822301324183a2a2743a4ed5db840253cc96b36694ef9e269d9 AS xx

# Stage - Build Drone SCP
FROM  golang:1.20-alpine@sha256:1e2917143ce7e7bf8d1add2ac5c5fa3d358b2b5ddaae2bd6f54169ce68530ef0 as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=appleboy/drone-scp
ARG DRONE_SCP_VERSION=v1.6.5

RUN apk --update --no-cache add git && \
    # Git clone specify drone-scp version
    git clone --branch ${DRONE_SCP_VERSION} https://github.com/appleboy/drone-scp . && \
    # Build drone-scp
    xx-go build -v -o /bin/drone-scp \
    -ldflags="-w -s -X 'main.Version=${DRONE_SCP_VERSION}'" . && \
    # Verify drone-scp
    xx-verify --static /bin/drone-scp

# Stage - Main Image
FROM plugins/base:latest@sha256:a7c0bb7766e462bb9bed21596da9ee6b2f74f035a4095d4076f2e4cf85876a64

# Copy Drone SCP binary to image
COPY --from=builder /bin/drone-scp /bin/drone-scp

ENTRYPOINT ["/bin/drone-scp"]
