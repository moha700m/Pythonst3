#!/bin/sh
# Copy the CPython standard library into the app bundle and convert extension
# modules into the .fwork/.framework layout required on iOS.
#
# This is an unsigned variant of Python-Apple-support's install_python helper:
# we intentionally skip codesign so the resulting IPA stays unsigned for ESign.
set -eu

XCFRAMEWORK="${PROJECT_DIR}/Frameworks/Python.xcframework"
BUNDLE="${CODESIGNING_FOLDER_PATH:?CODESIGNING_FOLDER_PATH is not set}"

if [ ! -d "$XCFRAMEWORK" ]; then
    echo "error: missing ${XCFRAMEWORK}. Run Scripts/fetch_python.sh first." >&2
    exit 1
fi

case "${EFFECTIVE_PLATFORM_NAME:-}" in
    -iphonesimulator)
        SLICE="ios-arm64_x86_64-simulator"
        ;;
    *)
        SLICE="ios-arm64"
        ;;
esac

ARCH="${ARCHS%% *}"
case "$ARCH" in
    arm64|x86_64) ;;
    *) ARCH="arm64" ;;
esac

echo "Embedding CPython stdlib for ${EFFECTIVE_PLATFORM_NAME:-device}/${ARCH}"

mkdir -p "$BUNDLE/python/lib"
rsync -a --delete --exclude 'libpython*.dylib' "$XCFRAMEWORK/lib/" "$BUNDLE/python/lib/"

if [ -d "$XCFRAMEWORK/$SLICE/lib-$ARCH" ]; then
    rsync -a "$XCFRAMEWORK/$SLICE/lib-$ARCH/" "$BUNDLE/python/lib/"
else
    echo "warning: no slice lib-$ARCH for $SLICE; extension modules may be unavailable" >&2
fi

PYVER="$(ls -1 "$BUNDLE/python/lib" | grep -E '^python3\.[0-9]+$' | head -n 1)"
if [ -z "$PYVER" ]; then
    echo "error: Python standard library was not copied correctly." >&2
    exit 1
fi

process_dylibs() {
    base="$1"
    find "$base" -name '*.so' -type f | while IFS= read -r so; do
        filename="$(basename "$so")"
        module="${filename%%.*}"
        relative="${so#"$BUNDLE/"}"
        framework_dir="$BUNDLE/Frameworks/$module.framework"

        mkdir -p "$framework_dir"
        cp "$XCFRAMEWORK/build/iOS-dylib-Info-template.plist" "$framework_dir/Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $module" "$framework_dir/Info.plist"
        safe_module="$(printf '%s' "$module" | tr '_' '-')"
        safe_module="py${safe_module#-}"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.moha700m.pythonst3.$safe_module" "$framework_dir/Info.plist"

        if [ "${EFFECTIVE_PLATFORM_NAME:-}" = "-iphonesimulator" ]; then
            /usr/libexec/PlistBuddy -c "Set :CFBundleSupportedPlatforms:0 iPhoneSimulator" "$framework_dir/Info.plist"
            /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 16.0" "$framework_dir/Info.plist"
        fi

        mv "$so" "$framework_dir/$module"
        printf 'Frameworks/%s.framework/%s' "$module" "$module" > "${so%.so}.fwork"
        printf '%s.fwork' "${relative%.so}" > "$framework_dir/$module.origin"
    done
}

process_dylibs "$BUNDLE/python/lib/$PYVER/lib-dynload"

echo "CPython ${PYVER} embedded: $(find "$BUNDLE/python/lib/$PYVER" -name '*.py' | wc -l | tr -d ' ') stdlib files, $(find "$BUNDLE/Frameworks" -maxdepth 1 -name '*.framework' | wc -l | tr -d ' ') extension frameworks."
