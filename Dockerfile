# Around The World — Vapor API
# Build from the repo root: docker build -t around-the-world-api .
# Railway auto-detects this file. Do not add a Railway Postgres plugin;
# DATABASE_URL must point at the existing Supabase project.

# ================================
# Build
# ================================
FROM swift:6.0.3-noble AS build

WORKDIR /build

COPY Backend/Package.swift ./
COPY Backend/Sources ./Sources
COPY Backend/Tests ./Tests

RUN swift package resolve \
 && swift build -c release --product App --static-swift-stdlib

RUN mkdir /staging \
 && cp "$(swift build -c release --show-bin-path)/App" /staging/ \
 && if [ -f /usr/libexec/swift/linux/swift-backtrace-static ]; then \
        cp /usr/libexec/swift/linux/swift-backtrace-static /staging/; \
    fi

# ================================
# Run
# ================================
FROM ubuntu:24.04

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -q update \
 && apt-get -q install -y --no-install-recommends \
        ca-certificates \
        tzdata \
        libcurl4 \
        libxml2 \
        libsqlite3-0 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app

COPY --from=build --chown=vapor:vapor /staging /app

ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

USER vapor:vapor

# Railway injects PORT. configure() reads it. Do not hard-code --port here.
EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
