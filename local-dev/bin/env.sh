# Shared by the bin scripts: where things are, and the settings from .env.
LOCAL_DEV="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$LOCAL_DEV/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$LOCAL_DEV/.env"
  set +a
fi
GHOSTSPEAK_HOME="${GHOSTSPEAK_HOME:-$(cd "$LOCAL_DEV/../.." && pwd)}"
FCM_KEY_FILE="$(cd "$LOCAL_DEV" && realpath -m "${FCM_KEY_FILE:-./secrets/fcm.json}")"
# the container gets the key's folder: a missing file mounted alone would come out a directory
FCM_KEY_DIR="$(dirname "$FCM_KEY_FILE")"
FCM_KEY_NAME="$(basename "$FCM_KEY_FILE")"

# the agent reads the key at its first push, and a missing key stops it
warn_without_fcm_key() {
  [ -f "$FCM_KEY_FILE" ] ||
    echo "warning: no $FCM_KEY_FILE: the agent will stop when it first sends a push message" >&2
}

# sbt from the PATH, else the launcher IntelliJ's Scala plugin ships
run_sbt() {
  local java_home="${SBT_JAVA_HOME:-${JAVA_HOME:-}}"
  if [ -z "$java_home" ] && ! command -v java >/dev/null; then
    # no JDK set up: take one IntelliJ downloaded
    java_home="$(ls -d "$HOME"/.jdks/*/ 2>/dev/null | tail -1)"
  fi
  [ -n "$java_home" ] && export JAVA_HOME="${java_home%/}"
  if command -v sbt >/dev/null; then
    sbt "$@"
  else
    local launcher
    launcher="$(ls "$HOME"/.local/share/JetBrains/*/Scala/launcher/sbt-launch.jar 2>/dev/null | tail -1)"
    if [ -z "$launcher" ]; then
      echo "sbt not found: install it, or IntelliJ's Scala plugin" >&2
      exit 1
    fi
    "${JAVA_HOME:+$JAVA_HOME/bin/}java" -jar "$launcher" "$@"
  fi
}
