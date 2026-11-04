FROM ghcr.io/berriai/litellm:v1.108.0
COPY railway-entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/bin/sh", "/railway-entrypoint.sh"]
