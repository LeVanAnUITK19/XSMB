# XSMB backend deploy package

Requires Node.js 22+.

1. Extract this ZIP into the backend service directory.
2. Copy `.env.example` to `.env` for local use, or set its variables in your hosting dashboard. Set the supplied Atlas URI in `MONGODB_URI`, `MONGODB_DB=xsmb`, and `MONGODB_COLLECTION=results`.
3. Set `CRAWLER_API_TOKEN` to the same private token used by the GitHub crawl workflows. The local project at D:/XSMB/backend/.env already has an individually generated token and the supplied URI; this ZIP intentionally excludes that file.
4. Run `npm ci --omit=dev`, then `npm start`.
5. Health check: `/healthz`. Public API base: `/api/`; write endpoint: `/api/results`.
6. After deployment, enter `https://your-backend.example/api/` in the XSMB app's server settings.

Docker: run `docker build -t xsmb-backend .`, then provide the environment variables to the container. This package has no internal cron process; scheduled crawls are prepared in the source project's `.github/workflows/` directory.

Do not put MongoDB credentials or the crawler token into the Flutter app or a public repository. The ZIP contains code, dependency lockfile and an environment example only.
