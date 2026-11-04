#!/bin/sh
# Writes LiteLLM's config from variables: spend log retention, and one wildcard model
# for each provider key set at deploy, so calls work with no setup in the admin UI.
set -e
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
exec docker/prod_entrypoint.sh --config "$CONFIG"
