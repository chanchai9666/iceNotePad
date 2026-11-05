#!/usr/bin/env bash
# Resolves the app version from $APP_VERSION or the VERSION file at the repo root.
# Expects $DIR to point at the repository root and echoes the validated version.

resolve_app_version() {
    local version_file="$DIR/VERSION"
    local version="${APP_VERSION:-}"

    if [[ -z "$version" && -f "$version_file" ]]; then
        version="$(tr -d '[:space:]' < "$version_file")"
    fi
    version="${version:-0.0.0}"

    if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+){2}$ ]]; then
        echo "error: invalid app version '$version' (expected MAJOR.MINOR.PATCH in $version_file)" >&2
        return 1
    fi

    printf '%s\n' "$version"
}
