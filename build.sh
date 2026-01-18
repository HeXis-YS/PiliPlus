#!/usr/bin/bash -e
export GRADLE_OPTS=-Dorg.gradle.daemon=false
export JAVA_HOME=$JAVA_HOME_21_X64

if [ ! -d flutter ]; then
    FLUTTER_VERSION="$(yq eval '.environment.flutter' pubspec.yaml)"
    git clone --depth 1 --single-branch -b $FLUTTER_VERSION https://github.com/flutter/flutter
    pushd flutter
    git apply ../lib/scripts/bottom_sheet_patch.diff
    popd
fi
export PATH=$(realpath flutter/bin):$PATH

GITHUB_ENV=/dev/null pwsh lib/scripts/build.ps1 android

flutter build apk --release --target-platform=android-arm64 --split-per-abi --dart-define-from-file=pili_release.json --pub

cp build/app/outputs/flutter-apk/*.apk ./
