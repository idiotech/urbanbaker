# Local development environment

Runs the Ghostspeak back end and editor on one machine:

| Service | Port | Runs |
| --- | --- | --- |
| router (Caddy) | **8000**: open the editor here | Docker |
| MySQL 8.4 | 3306 | Docker |
| Redis | 6379 | Docker |
| ghostspeak-agent | 8080 | host (`bin/agent`), or Docker |
| ghostspeak-auth | 8082 | host (`bin/auth`), or Docker |
| ghostspeak-editor (Vite) | 4444 | host (`bin/editor`), or Docker |

The router puts everything behind `http://localhost:8000`, as production puts it behind one domain:
`/v1/user/*` goes to auth, the rest of `/v1/*` to the agent, everything else to the editor. It also
serves the editor's `/appConfigs.js`, pointing the editor at `http://localhost:8000`, so the editor
checkout needs no changes. All ports listen on 127.0.0.1 only.

The checkouts of `ghostspeak-agent`, `ghostspeak-auth` and `ghostspeak-editor` are expected next to
`urbanbaker`; set `GHOSTSPEAK_HOME` in `.env` otherwise.

## Requirements

- Docker with Compose v2 (openSUSE: `sudo zypper install docker docker-compose`,
  `sudo systemctl enable --now docker`, `sudo usermod -aG docker $USER`, then log in again).
- For running services on the host:
  - sbt, or IntelliJ with the Scala plugin, whose sbt launcher the scripts use;
  - a JDK 17 or newer (tested with 23 and 26): `SBT_JAVA_HOME`, else `JAVA_HOME`, else the `java`
    on the PATH, else one IntelliJ downloaded to `~/.jdks`;
  - Node 22 for the editor.

## First time

1. `cp .env.example .env` and adjust it if needed.
2. The editor's Firebase settings: put `src/FIREBASE_CONFIG.js` in the editor checkout (it is
   gitignored). It exports `firebaseConfig` for the **production** Firebase project:
   ```js
   export const firebaseConfig = {
     apiKey: "…", authDomain: "…", databaseURL: "…", projectId: "…", storageBucket: "…",
     messagingSenderId: "…",
   };
   ```
   The values are in the Firebase console, under Project settings → Your apps → the web app.
3. The agent's FCM service-account JSON at `secrets/fcm.json` (gitignored), or another path in
   `FCM_KEY_FILE`, in a folder of its own: under the `full` profile the container gets the whole
   folder. Without it the agent runs until it first sends a push message, as when a story starts
   on a phone, and then stops; the editor works without it.

## Running

Infrastructure first, then each service in its own terminal:

```sh
bin/compose up -d    # MySQL, Redis, router
bin/agent            # builds with sbt, then runs; bin/agent <sbt commands> runs those instead
bin/auth             # the same, e.g. bin/auth test
bin/editor           # npm start
```

Open http://localhost:8000 and sign in with Google.

To make yourself a superuser, who sees every story rather than only their own, find your uid in
the Firebase console (Authentication → Users), then:

```sh
bin/superuser <uid>
```

Or run everything in Docker; the first build takes several minutes:

```sh
bin/compose --profile full up --build
```

## Day to day

- Each service can run on the host or in Docker, not both: they share ports.
- After installing Docker, log in again for the `docker` group to apply, or run `newgrp docker`.
- On SELinux systems (openSUSE, Fedora), Compose relabels what it mounts (`:z`), including the
  editor checkout under the `full` profile, so containers may read it.
- Running from IntelliJ instead of `bin/agent` or `bin/auth`: copy the environment variables the
  script exports into the run configuration.
- `bin/compose down` stops everything; `bin/compose down -v` also deletes the MySQL data and the
  editor's container `node_modules`.
- MySQL: `bin/compose exec mysql mysql -ughostspeak -pghostspeak ghostspeak`. Databases:
  `ghostspeak` (the agent's journal), `ghostspeak-log` (its performance log), `ghostspeak_auth`.

## The Android app

A debug build of `ghostspeak-client` talks to the server named by `ghostspeak_api_url`, set in its
`local.properties` or as a Gradle property (`-Pghostspeak_api_url=…`); without it, and in release
builds, it talks to production. Debug builds allow plain HTTP to the addresses below.

- **Emulator:** `ghostspeak_api_url=http://10.0.2.2:8000/`, the emulator's address for this machine.
- **Phone on USB:** `ghostspeak_api_url=http://localhost:8000/`, then, each time the phone is
  connected, `adb reverse tcp:8000 tcp:8000`.

The router listens on 127.0.0.1 only, so a phone on Wi-Fi cannot reach it; opening it to the
network would open the agent and the superuser endpoint to everyone on it.

The app sends its events over HTTP, but the agent answers with push messages: without
`secrets/fcm.json`, for the Firebase project the app is built with, the agent stops as a story
starts. The local agent starts with no stories or categories: publish them from the local
editor. Uploads, sounds and images still come from the production hosts.

## Things to know

- **The editor uses the production Firebase project.** Signing in, and every story, category and
  image the editor saves to Firestore or Storage, is real production data. Only what the editor
  sends to the agent (published scenarios, broadcasts) stays local.
- **Push messages are real.** With a production FCM key, the local agent sends real pushes, to the
  devices that send it events. The Android app talks to `https://api.urbanbaker.tw/` unless a
  debug build is pointed here; see below.
- **The superuser endpoint is unauthenticated**, as in production: anyone who can reach it can ask
  whether a uid is a superuser.
- Production hosts still in the editor: the Google Maps key in `index.html`, and images from
  `storage.googleapis.com` and `daqiaotou-storage.floraland.tw`.
