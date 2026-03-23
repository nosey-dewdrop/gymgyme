# USDA Food Search Proxy

Cloudflare Worker that proxies USDA FoodData Central API requests.
API key stays on the server, never exposed in the iOS app.

## Setup

```bash
npm install -g wrangler
wrangler login
wrangler secret put USDA_API_KEY
# paste your key: kvDdbv9WdNmT8MCiWyqEU3NoPQkqfaLqsoRlTlAG
wrangler deploy
```

## Usage

```
GET https://gymgyme-usda-proxy.<your-subdomain>.workers.dev/search?query=chicken+breast&pageSize=15
```

Returns same JSON as USDA API.
