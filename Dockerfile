# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Drone SCP
FROM  golang:1.20-alpine@sha256:48f336ef8366b9d6246293e3047259d0f614ee167db1869bdbc343d6e09aed8a as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=appleboy/drone-scp
ARG DRONE_SCP_VERSION=v1.6.6

RUN apk --update --no-cache add git && \
    # Git clone specify drone-scp version
    git clone --branch ${DRONE_SCP_VERSION} https://github.com/appleboy/drone-scp . && \
    # Build drone-scp
    xx-go build -v -o /bin/drone-scp \
    -ldflags="-w -s -X 'main.Version=${DRONE_SCP_VERSION}'" . && \
    # Verify drone-scp
    xx-verify --static /bin/drone-scp

# Stage - Main Image
FROM plugins/base:latest@sha256:83a0c6ac50408cd262b5273e7009de9b9bcd0fa55a15b7e33d5978c9702acc96

# Copy Drone SCP binary to image
COPY --from=builder /bin/drone-scp /bin/drone-scp

ENTRYPOINT ["/bin/drone-scp"]
