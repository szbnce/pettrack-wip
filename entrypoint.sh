#!/bin/sh
# Before the server starts, make sure every mounted path is the kind of
# thing the server expects.
#
# A Docker bind mount whose host path did not exist is created by Docker as
# a *directory*. `./pettrack_server/pettrack.db:/app/pettrack.db` then
# becomes a folder called pettrack.db, and every one of these wants a
# different kind of thing. It used to surface as a forty-line traceback
# loop instead of one sentence about what to do.
set -e

say() { echo "pettrack: $*"; }

# $1 path · $2 "file" | "dir" · $3 one-line explanation of what it holds
ensure() {
    path="$1"; kind="$2"; what="$3"
    if [ "$kind" = "file" ] && [ -d "$path" ]; then
        say "$path is a directory, but it should be a file."
        say "  It holds $what."
        say "  On the host: move that folder aside (it is probably empty),"
        say "  then 'touch ${path#/app/}' next to your docker-compose.yml and start again."
        exit 1
    fi
    if [ "$kind" = "dir" ] && [ -f "$path" ]; then
        say "$path is a file, but it should be a directory."
        say "  It holds $what."
        say "  On the host: move that file aside, 'mkdir ${path#/app/}' and start again."
        exit 1
    fi
    if [ "$kind" = "file" ] && [ ! -e "$path" ]; then
        : > "$path"
    fi
    if [ "$kind" = "dir" ] && [ ! -d "$path" ]; then
        mkdir -p "$path"
    fi
}

ensure /app/pettrack.db      file "the database"
ensure /app/replays          dir  "recorded clips"
ensure /app/captured_images  dir  "snapshots"
ensure /app/updates          dir  "staged app updates"

# `.env` as a directory is the one shape the server can work with anyway:
# settings fall back to .env/pettrack.env, which lives on the same mount
# and so survives a rebuild. Say so, rather than failing.
if [ -d /app/.env ]; then
    say "/app/.env is a directory (a bind mount with no host file behind it)."
    say "  Settings will be kept at .env/pettrack.env on that mount instead."
elif [ ! -e /app/.env ]; then
    : > /app/.env
fi

exec "$@"
