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
  - a JDK 17 to 23: sbt 1.9, which the agent uses, does not run on newer ones. The scripts take the
    first one in `~/.jdks` (IntelliJ downloads JDKs there), or `SBT_JAVA_HOME`;
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
3. Optional: the agent's FCM service-account JSON at `secrets/fcm.json` (gitignored), or another
   path in `FCM_KEY_FILE`. Without it the agent runs, but cannot send push messages.

## Running

Infrastructure first, then each service in its own terminal:

```sh
bin/compose up -d    # MySQL, Redis, router
bin/agent            # sbt example/run; bin/agent <sbt commands> runs those instead
bin/auth             # sbt run
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
- Running from IntelliJ instead of `bin/agent` or `bin/auth`: copy the environment variables the
  script exports into the run configuration.
- `bin/compose down` stops everything; `bin/compose down -v` also deletes the MySQL data and the
  editor's container `node_modules`.
- MySQL: `bin/compose exec mysql mysql -ughostspeak -pghostspeak ghostspeak`. Databases:
  `ghostspeak` (the agent's journal), `ghostspeak-log` (its performance log), `ghostspeak_auth`.

## Things to know

- **The editor uses the production Firebase project.** Signing in, and every story, category and
  image the editor saves to Firestore or Storage, is real production data. Only what the editor
  sends to the agent (published scenarios, broadcasts) stays local.
- **Push messages are real.** With a production FCM key, the local agent sends real pushes. The
  Android app talks to `https://api.urbanbaker.tw/`, fixed when it is built, so phones do not reach
  the local agent unless built against it.
- **The superuser endpoint is unauthenticated**, as in production: anyone who can reach it can ask
  whether a uid is a superuser.
- Production hosts still in the editor: the Google Maps key in `index.html`, and images from
  `storage.googleapis.com` and `daqiaotou-storage.floraland.tw`.
