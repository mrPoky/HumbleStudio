#!/bin/sh
set -eu

SRCROOT="${SRCROOT:?SRCROOT must be set}"
TARGET_DIR="${TARGET_BUILD_DIR:?TARGET_BUILD_DIR must be set}"
RESOURCES_DIR="${UNLOCALIZED_RESOURCES_FOLDER_PATH:?UNLOCALIZED_RESOURCES_FOLDER_PATH must be set}"
WEB_DESTINATION="$TARGET_DIR/$RESOURCES_DIR/WebStudio"

rm -rf "$WEB_DESTINATION"
mkdir -p "$WEB_DESTINATION"

copy_path() {
  rsync -a --delete --exclude '.DS_Store' "$SRCROOT/$1" "$WEB_DESTINATION/"
}

copy_path "index.html"
copy_path "studio.css"
copy_path "design.template.json"
copy_path "configs"
copy_path "js"
