#!/bin/sh

set -e

PROJECT_NAME="check-your-lua"
SRC_DIR="src"
BIN_DIR="bin"
TEST_DIR="tests"
LUA="lua"

case "$1" in
  build)
    echo "Building $PROJECT_NAME..."
    mkdir -p "$BIN_DIR"
    cp "$SRC_DIR"/*.lua "$BIN_DIR/"
    ;;
  test)
    echo "Running tests..."
    "$LUA" "$TEST_DIR"/*.lua
    ;;
  clean)
    echo "Cleaning up..."
    rm -rf "$BIN_DIR"
    ;;
  install)
    echo "Installing $PROJECT_NAME..."
    cp "$BIN_DIR/$PROJECT_NAME" /usr/local/bin/
    ;;
  help)
    echo "Usage: $0 {build|test|clean|install|help}"
    ;;
  *)
    echo "Invalid command. Use 'help' for usage."
    exit 1
    ;;
esac
