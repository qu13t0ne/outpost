FROM caddy:2-builder as builder

RUN caddy-builder \
	github.com/greenpau/caddy-security

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy