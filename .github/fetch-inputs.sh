#!/usr/bin/env bash
# The builds and the installer scripts for $VERSION, from the draft release build-inputs-$VERSION that the
# private repository's release workflow hands over: every asset into inputs/, then installers.tar.gz unpacked
# here as installers/. Needs GH_TOKEN with read access to this repository's releases (drafts included).
set -euo pipefail
case "${VERSION:-}" in v[0-9]*) ;; *) echo "::error::no version to build ($VERSION): give one like v3.0.0"; exit 1;; esac
id=$(gh api "repos/$GITHUB_REPOSITORY/releases?per_page=100" \
       --jq ".[] | select(.draft and .name == \"build-inputs-$VERSION\") | .id" | head -n 1)
if [ -z "$id" ]; then
  echo "::error::no draft release build-inputs-$VERSION holds the builds"
  exit 1
fi
echo "INPUTS_RELEASE_ID=$id" >> "$GITHUB_ENV"
mkdir -p inputs
gh api "repos/$GITHUB_REPOSITORY/releases/$id/assets?per_page=100" --jq '.[] | "\(.id) \(.name)"' |
  while read -r asset name; do
    gh api -H "Accept: application/octet-stream" "repos/$GITHUB_REPOSITORY/releases/assets/$asset" > "inputs/$name"
  done
tar -xzf inputs/installers.tar.gz
ls -la inputs installers
