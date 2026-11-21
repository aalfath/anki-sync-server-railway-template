[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/anki-sync-server-1?utm_medium=integration&utm_source=button&utm_campaign=anki-sync-server)

# Anki Sync Server on Railway

One-click Railway template for the official [Anki](https://apps.ankiweb.net/) self-hosted sync server by Ankitects. Sync your decks, review history and media between Anki Desktop, AnkiMobile and AnkiDroid through your own server instead of AnkiWeb.

**Version:** Anki **26.09.4** (`anki==26.9.4` from PyPI, the official Ankitects wheel that contains the Rust sync server), on `python:3.14.9-slim-trixie@sha256:35caba83af2fe6da9a5d922f9b0156f21d1246a48278c58a08bd253303ba42e8`. Every Python package is pinned by version and sha256 hash in [`requirements.txt`](requirements.txt).

## What the template deploys

One service, **Anki Sync Server**, built from this repo's `Dockerfile`:

- runs `python -m anki.syncserver` on Railway's `PORT` (8080), behind a public Railway HTTPS domain;
- stores every user's collection and media on a Railway volume mounted at `/anki_data`;
- answers `GET /health` (no login) for Railway's health check;
- creates the first account from `ANKI_USERNAME` and a generated `ANKI_PASSWORD`. There is no default password.

No database is needed: the server keeps each account's collection as an SQLite file on the volume.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `ANKI_USERNAME` | `anki` | Username for the first sync account (no `:`). |
| `ANKI_PASSWORD` | `${{secret(24)}}` | Password for that account, generated at deploy. Read it in the service's Variables tab. |
| `PORT` | `8080` | Port the server listens on. |

Optional, add them in the service's Variables tab when you need them:

- `SYNC_USER2`, `SYNC_USER3`, … in `user:password` format for more accounts. Each account has its own collection.
- `SYNC_USER1=user:password` replaces `ANKI_USERNAME`/`ANKI_PASSWORD`. With `PASSWORDS_HASHED=1`, the `SYNC_USER*` passwords are PHC-format PBKDF2 hashes instead of plain text ([upstream docs](https://docs.ankiweb.net/sync-server.html#hashed-passwords)).
- `MAX_SYNC_PAYLOAD_MEGS` (default `100`): largest accepted upload in MB. Raise it for very large collections.

## After deploying

1. Open the service's **Variables** tab and copy `ANKI_USERNAME` and `ANKI_PASSWORD`.
2. In Anki Desktop: *Preferences → Syncing → Self-hosted sync server*, enter `https://YOUR-DOMAIN.up.railway.app/` (your service's public domain, with the trailing slash), restart Anki, then click **Sync** and log in. AnkiDroid and AnkiMobile have the same "custom sync server" setting in their sync preferences: use the same URL.
3. On the first sync choose **Upload to AnkiWeb** on the device that has your collection; other devices then choose **Download**.

Anki's messages still say "AnkiWeb" when a custom server is set: that's expected.

## Updates

When this repo's `main` changes (for example a new Anki release), Railway shows deployers an "update available" notice; you choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first. Ankitects notes that newer Anki clients may need a newer sync server, so keep the server at least as new as your clients.

Your data stays on the volume across updates, redeploys and restarts. To back it up, use Railway's volume backups.

## Local run

```sh
docker build -t anki-sync-server .
docker run -p 8080:8080 -e ANKI_PASSWORD=change-me -v anki-data:/anki_data anki-sync-server
```

`test/client.py` is a headless end-to-end check (log in, full upload with a note and a media file, then download into a fresh collection) using the same `anki` package.

## License

Anki is © Ankitects Pty Ltd and contributors, licensed under the GNU AGPL v3 or later. This wrapper (Dockerfile, start script, docs) is provided under the same license.
