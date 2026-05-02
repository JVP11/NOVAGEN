# NOVAGEN

## Docker deploy (Render Web Service)

This repo now includes a root `Dockerfile` for deploying the Flutter web app
(`files(1)/`) as a Render **Web Service** (Docker).

### Render settings

- Service type: `Web Service`
- Runtime: `Docker`
- Root directory: *(empty)* 
- Dockerfile path: `Dockerfile`

Render will build the image, then run a static server that listens on
`$PORT` automatically.

### Local Docker test

```bash
cd /home/jonathan/novagen
docker build -t novagen-safeink .
docker run --rm -p 10000:10000 -e PORT=10000 novagen-safeink
```

Open: `http://localhost:10000`