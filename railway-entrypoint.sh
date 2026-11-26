#!/bin/sh
# Writes LiteLLM's config from variables: spend log retention, and one wildcard model
# for each provider key set at deploy, so calls work with no setup in the admin UI.
set -e

# From v1.111.0 LiteLLM holds about 1.1 GB once started (v1.110 needed about 650 MB).
# Under about 1.4 GB it stalls before printing anything, so the service just never comes
# up. Say why on the page instead, and keep the healthcheck green.
lim=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [ "$lim" != max ] && [ "$lim" -lt 1400000000 ] 2>/dev/null; then
  mb=$((lim / 1048576))
  echo "LiteLLM needs 1.5 GB of memory (2 GB recommended) and this service has ${mb} MB: serving a notice page instead. Raise the memory limit, then redeploy."
  exec env MB="$mb" python3 -c '
import http.server, os, socket
msg = ("LiteLLM could not start: from v1.111.0 it needs at least 1.5 GB of memory (2 GB recommended) and this service has %s MB. "
       "Below that it stalls while starting. Raise the memory limit in the service settings, then redeploy. "
       "Your keys and settings in Postgres are untouched.\n" % os.environ["MB"]).encode()
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        ok = self.path.startswith("/health/liveliness")
        self.send_response(200 if ok else 503); self.send_header("content-type", "text/plain; charset=utf-8"); self.end_headers()
        self.wfile.write(b"ok\n" if ok else msg)
    do_POST = do_HEAD = do_GET
    def log_message(self, *a): pass
class S(http.server.ThreadingHTTPServer): address_family = socket.AF_INET6
S(("::", int(os.environ.get("PORT", "4000"))), H).serve_forever()'
fi

CONFIG=/tmp/litellm-config.yaml
{
  echo 'general_settings:'
  if [ -n "$SPEND_LOGS_RETENTION" ]; then
    echo "  maximum_spend_logs_retention_period: \"$SPEND_LOGS_RETENTION\""
  fi
  echo '  store_model_in_db: true'
  echo 'model_list:'
  [ -z "$OPENAI_API_KEY" ]     || printf '  - model_name: "openai/*"\n    litellm_params:\n      model: "openai/*"\n      api_key: os.environ/OPENAI_API_KEY\n'
  [ -z "$ANTHROPIC_API_KEY" ]  || printf '  - model_name: "anthropic/*"\n    litellm_params:\n      model: "anthropic/*"\n      api_key: os.environ/ANTHROPIC_API_KEY\n'
  [ -z "$GEMINI_API_KEY" ]     || printf '  - model_name: "gemini/*"\n    litellm_params:\n      model: "gemini/*"\n      api_key: os.environ/GEMINI_API_KEY\n'
  [ -z "$OPENROUTER_API_KEY" ] || printf '  - model_name: "openrouter/*"\n    litellm_params:\n      model: "openrouter/*"\n      api_key: os.environ/OPENROUTER_API_KEY\n'
} > "$CONFIG"
# v1.111.0 moved the image entrypoint (docker/prod_entrypoint.sh is gone); with no
# component named it still runs the whole proxy in one process.
exec /app/docker-entrypoint.sh --config "$CONFIG"
