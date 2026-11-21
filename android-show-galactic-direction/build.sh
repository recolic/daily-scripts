#!/usr/bin/env bash
# created by Gemini 4 Hydrogen
set -euo pipefail
cd "$(dirname "$0")"

TOOLCHAIN_DIR="$PWD/.toolchain"
GRADLE_VER="8.11.1"
CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

if [ -z "${JAVA_HOME:-}" ]; then
    for candidate in /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/java-17-openjdk; do
        if [ -d "$candidate" ]; then export JAVA_HOME="$candidate"; break; fi
    done
fi

if [ -z "${GRADLE_HOME:-}" ] && ! command -v gradle >/dev/null 2>&1; then
    if [ ! -x "$TOOLCHAIN_DIR/gradle-$GRADLE_VER/bin/gradle" ]; then
        mkdir -p "$TOOLCHAIN_DIR"
        curl -fL "https://services.gradle.org/distributions/gradle-$GRADLE_VER-bin.zip" -o "$TOOLCHAIN_DIR/gradle.zip"
        unzip -q "$TOOLCHAIN_DIR/gradle.zip" -d "$TOOLCHAIN_DIR"
        rm -f "$TOOLCHAIN_DIR/gradle.zip"
    fi
    export GRADLE_HOME="$TOOLCHAIN_DIR/gradle-$GRADLE_VER"
fi

GRADLE_BIN="${GRADLE_HOME:+$GRADLE_HOME/bin/}gradle"
command -v "$GRADLE_BIN" >/dev/null 2>&1 || GRADLE_BIN="gradle"

if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
    export ANDROID_HOME="$TOOLCHAIN_DIR/android-sdk"
    if [ ! -d "$ANDROID_HOME/platforms/android-35" ] || [ ! -d "$ANDROID_HOME/build-tools/35.0.0" ]; then
        mkdir -p "$ANDROID_HOME/cmdline-tools"
        if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
            curl -fL "$CMDLINE_URL" -o "$TOOLCHAIN_DIR/cmdline-tools.zip"
            unzip -q "$TOOLCHAIN_DIR/cmdline-tools.zip" -d "$TOOLCHAIN_DIR/tmp-tools"
            mv "$TOOLCHAIN_DIR/tmp-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
            rm -rf "$TOOLCHAIN_DIR/tmp-tools" "$TOOLCHAIN_DIR/cmdline-tools.zip"
        fi
        yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --licenses >/dev/null || true
        "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-35" "build-tools;35.0.0"
    fi
fi

"$GRADLE_BIN" :app:assembleDebug "$@"
echo "APK: $PWD/app/build/outputs/apk/debug/app-debug.apk"
