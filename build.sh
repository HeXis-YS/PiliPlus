#!/usr/bin/bash -e
# export GRADLE_OPTS=-Dorg.gradle.daemon=false
export JAVA_HOME=$JAVA_HOME_17_X64

if [ ! -d flutter ]; then
    FLUTTER_VERSION="$(yq eval '.environment.flutter' pubspec.yaml)"
    git clone --single-branch -b $FLUTTER_VERSION https://github.com/flutter/flutter

    FLUTTER_ROOT=$(realpath flutter) GITHUB_WORKSPACE=$(realpath .) pwsh lib/scripts/patch.ps1 android
fi

if false; then
if [ -f flutter/engine/srcout/android_release_arm64/lib.stripped/libflutter.so ]; then
    cp -v flutter/engine/srcout/android_release_arm64/lib.stripped/libflutter.so ./libflutter.so
else
    pushd flutter

    cp engine/scripts/standard.gclient .gclient
    git clone --depth 1 --single-branch --no-tags https://chromium.googlesource.com/chromium/tools/depot_tools.git
    export PATH=$(realpath depot_tools):$PATH

    gclient sync --no-history

    install -m 0755 ../ndk-wrapper.py engine/src/flutter/buildtools/linux-x64/clang/bin/ndk-wrapper.py

    for tool in clang clang++; do
        tool_path="engine/src/flutter/buildtools/linux-x64/clang/bin/$tool"
        backup_path="${tool_path}_"

        if [[ ! -e "$backup_path" ]]; then
            if [[ "$tool" == "clang++" && -L "$tool_path" ]]; then
                # Keep clang++_ pointing at clang_ to avoid wrapper recursion.
                rm -f "$tool_path"
                ln -sfn "clang_" "$backup_path"
            else
                mv "$tool_path" "$backup_path"
            fi
        fi

        ln -sfn "ndk-wrapper.py" "$tool_path"
    done

    pushd engine/src
    flutter/tools/gn --runtime-mode=release --android --android-cpu arm64
    NDK_WRAPPER_APPEND="-march=armv9-a+crypto+nosve+bf16+fp16fml+i8mm+memtag+pmuv3+profile -mtune=cortex-a510" ninja -C out/android_release_arm64
    popd

    popd
fi
fi

export PATH=$(realpath flutter/bin):$PATH

GITHUB_ENV=/dev/null pwsh lib/scripts/build.ps1 android

flutter build apk --release --target-platform=android-arm64 --split-per-abi --dart-define-from-file=pili_release.json --pub

cp build/app/outputs/flutter-apk/*.apk ./
