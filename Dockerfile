# This is an example build stage for the node template. Here we create the binary in a temporary image.

# This is a base image to build substrate nodes
FROM docker.io/paritytech/ci-linux:production as builder

WORKDIR /subtensor
COPY . .
RUN cargo build --locked --release

# This is the 2nd stage: a very small image where we copy the binary."
FROM docker.io/library/ubuntu:20.04
LABEL description="Multistage Docker image for Subtensor Node" \
  image.type="builder" \
  image.authors="oliverlim818@gmail.com" \
  image.vendor="Taostats" \
  image.description="Multistage Docker image for Subtensor Node" \
  image.source="https://github.com/opentensor/subtensor" \
  image.documentation="https://github.com/opentensor/subtensor"

# Copy the node binary.
COPY --from=builder /subtensor/target/release/node-subtensor /usr/local/bin

RUN useradd -m -u 1000 -U -s /bin/sh -d /node-dev node-dev && \
  mkdir -p /chain-data /node-dev/.local/share && \
  chown -R node-dev:node-dev /chain-data && \
  ln -s /chain-data /node-dev/.local/share/node-subtensor && \
  # unclutter and minimize the attack surface
  rm -rf /usr/bin /usr/sbin && \
  # check if executable works in this container
  /usr/local/bin/node-subtensor --version

USER node-dev

EXPOSE 30333 9933 9944 9615
VOLUME ["/chain-data"]

ENTRYPOINT ["/usr/local/bin/node-subtensor"]