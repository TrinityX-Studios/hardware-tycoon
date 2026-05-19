#!/bin/bash
set -e

# Hardware Tycoon compile script
# Builds a release or debug version of the application.

# Targets: apk (default), linux, etc.
TARGET="apk"
BUILD_MODE="debug"

usage() {
  echo "Usage: ./build.sh [debug|release] [apk|linux]"
  echo "Default is debug apk."
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    debug)
      BUILD_MODE="debug"
      ;;
    release)
      BUILD_MODE="release"
      ;;
    apk)
      TARGET="apk"
      ;;
    linux)
      TARGET="linux"
      ;;
    -h|--help)
      usage
      ;;
    *)
      # Allow custom flutter build options
      ;;
  esac
done

# Extract Git commit id and tag
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
# For release, get the latest tag name, fallback to git describe --always
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || git describe --tags --always 2>/dev/null || echo "v1.0.0-alpha.1")

echo "--------------------------------------------------------"
echo "HARDWARE TYCOON BUILD PIPELINE"
echo "--------------------------------------------------------"
echo "Target Platform : $TARGET"
echo "Build Mode      : $BUILD_MODE"
echo "Git Commit ID   : $COMMIT_HASH"
echo "Git Tag (Latest): $LATEST_TAG"
echo "--------------------------------------------------------"

# Assemble dynamic definitions
DEFINES=(
  "--dart-define=BUILD_TYPE=$BUILD_MODE"
  "--dart-define=GIT_COMMIT=$COMMIT_HASH"
  "--dart-define=GIT_TAG=$LATEST_TAG"
  "--dart-define=BUILD_TIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
)

# Run flutter compiler
if [ "$BUILD_MODE" = "release" ]; then
  flutter build "$TARGET" --release "${DEFINES[@]}"
else
  flutter build "$TARGET" --debug "${DEFINES[@]}"
fi

echo "--------------------------------------------------------"
echo "BUILD PIPELINE SUCCESSFUL!"
echo "--------------------------------------------------------"
