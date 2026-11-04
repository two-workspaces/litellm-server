# Deploy and Host LiteLLM on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/litellm-server?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=litellm-server)

[LiteLLM](https://www.litellm.ai/) is an open source AI gateway. It puts OpenAI, Anthropic, Gemini, OpenRouter and 100+ other model providers behind one OpenAI-compatible API, with virtual keys, budgets and spend tracking. Your apps talk to one URL and never hold a provider key.

## About Hosting LiteLLM

Two services: **LiteLLM** and **Postgres**, which keeps models, keys and spend logs on a volume.

- **Paste a key and start calling.** Add a provider key when you deploy, and every model from that provider works straight away, as `openai/<model>` or `anthropic/<model>`. No setup in the admin UI. You can still add more models there.
- **The domain opens the admin UI.** Upstream shows its API docs at the root, so the login page is easy to miss. The docs move to `/docs`.
- **Request logs get cleaned up.** Logs older than 30 days are deleted once a day, so they don't slowly fill the database. Change it with `SPEND_LOGS_RETENTION`.
- **No Redis to pay for.** One LiteLLM instance doesn't need it. Add Redis only when you run more than one.
- **A pinned version.** A redeploy never pulls an untested release.

## Common Use Cases

- One API for your apps, so you can switch model providers without changing code
- Giving each app, teammate or customer their own key, limited to certain models and a budget
- Seeing what you spend on AI per key, team and model
- Automatic fallback to another provider when one fails or rate limits you
- An AI backend for n8n, Open WebUI, coding agents and anything else that speaks the OpenAI API

## Dependencies for LiteLLM Hosting

- At least one model provider API key, added at deploy or later

### Deployment Dependencies

- [LiteLLM proxy documentation](https://docs.litellm.ai/docs/simple_proxy)
- [Supported providers](https://docs.litellm.ai/docs/providers)
- [LiteLLM on GitHub](https://github.com/BerriAI/litellm)

### Implementation Details

**First steps**

1. Open the LiteLLM service's domain and sign in as `admin`. The password is `LITELLM_MASTER_KEY` in the service's Variables.
2. Under **Virtual Keys**, create a key for your app, rather than handing out the master key.
3. Point your app at `https://<your-domain>/v1` with that key.

```bash
curl https://<your-domain>/v1/chat/completions \
  -H "Authorization: Bearer <virtual-key>" \
  -H "Content-Type: application/json" \
  -d '{"model": "openai/gpt-4o-mini", "messages": [{"role": "user", "content": "Hello"}]}'
```

**Provider keys.** `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` and `OPENROUTER_API_KEY` each turn on that provider's models as `provider/<model>`. Set them at deploy or later in Variables, which restarts the service. OpenRouter models work but do not show up in `/v1/models`. For anything else, add the model under **Models + Endpoints**. Keys you add there are encrypted in the database.

**Keep the salt key.** `LITELLM_SALT_KEY` encrypts the provider keys stored in the database. Back it up and never change it, or those keys become unreadable.

**Banners in the admin UI.** "Environment-credential login is enabled" means the master key can sign in as admin, which is how you get in the first time. To close it, create an admin account with its own password, then follow the fix the banner links to.

**Memory.** LiteLLM uses about 600 MB at idle and about 750 MB once it has served requests, more than most gateways, so give it at least 1 GB. Postgres adds about 60 MB, and more as logs grow.

**Running more than one replica.** Rate limits and budgets then need to be shared between instances. Add a Redis service and set `REDIS_HOST`, `REDIS_PORT` and `REDIS_PASSWORD` on LiteLLM.

**Licence.** LiteLLM's core is MIT. Some features, like SSO, need a LiteLLM Enterprise licence.

## Why Deploy LiteLLM on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying LiteLLM on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
