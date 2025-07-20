#!/usr/bin/env bash

# notify.sh - Send desktop notifications across macOS and Linux
# Usage: ./notify.sh

# Get the current directory
CURRENT_DIR="$(pwd)"
MESSAGE="Claude needs your attention in ${CURRENT_DIR}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
OS="$(uname -s)"

case "${OS}" in
Darwin*)
    # macOS
    if command_exists osascript; then
        osascript -e "display notification \"${MESSAGE}\" with title \"Claude CLI\""
        exit 0
    else
        echo "Error: osascript not found on macOS" >&2
        exit 1
    fi
    ;;

Linux*)
    # Linux
    # Try notify-send first
    if command_exists notify-send; then
        notify-send "Claude CLI" "${MESSAGE}"
        exit 0
    # Fallback to dunstify
    elif command_exists dunstify; then
        dunstify "Claude CLI" "${MESSAGE}"
        exit 0
    else
        echo "Error: Neither notify-send nor dunstify found on Linux" >&2
        echo "Please install libnotify-bin or dunst" >&2
        exit 1
    fi
    ;;

*)
    # Unsupported OS
    echo "Error: Unsupported operating system: ${OS}" >&2
    exit 1
    ;;
esac
