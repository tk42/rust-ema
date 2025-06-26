# rust-ema

## Build rtsdk-base image

```bash
docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile.rtsdk-base \
  -t rtsdk-base:local \
  .
```

## Build app image

```bash
docker compose build
```
