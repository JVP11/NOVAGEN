FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TAR_OPTIONS=--no-same-owner
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (stable) in build stage.
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

WORKDIR /app
COPY files(1) /app/files(1)

WORKDIR /app/files(1)
RUN flutter --version && \
    flutter config --no-analytics --enable-web && \
    flutter precache --web && \
    flutter pub get && \
    flutter build web --release

# Runtime stage: static web serving on Render-provided PORT.
FROM node:20-alpine
WORKDIR /site
RUN npm install -g serve
COPY --from=builder /app/files(1)/build/web /site

ENV PORT=10000
EXPOSE 10000
CMD ["sh", "-c", "serve -s /site -l ${PORT}"]
