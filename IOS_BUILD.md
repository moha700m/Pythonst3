# Pythonst3 — iOS Build and Unsigned IPA

This document covers the native iOS application and the GitHub Actions pipeline that produces an **unsigned** IPA for the owner to sign with ESign.

## What is built

- Native SwiftUI application, bundle identifier `com.moha700m.pythonst3`.
- Minimum deployment target: iOS 16.0.
- Arabic RTL interface with a cyberpunk visual identity; code editor is forced LTR.
- Project/file explorer, editor tabs, Python syntax highlighting, line numbers, autosave, import/export.
- Embedded CPython runtime with stdout/stderr capture, tracebacks, interactive `input()`, Stop and timeout.
- Optional AI assistant with a provider adapter (OpenAI-compatible or Anthropic). API keys live in the iOS Keychain and are never committed or bundled.
- No subprocess, shell, arbitrary pip installs, or background execution. Those are platform limitations, not hidden behaviour.

## Embedded Python

| Item | Value |
|---|---|
| Runtime | CPython 3.13.18 |
| Distribution | BeeWare Python-Apple-support `3.13-b18` |
| Archive | `Python-3.13-iOS-support.b18.tar.gz` |
| SHA-256 | `d06acf2a9c7964a8689566353a0e707402eff822037de5e29ba0e16040f7047d` |
| Minimum iOS in framework | 13.0 (app targets 16.0) |
| App path | `Python.framework` + `python/lib/python3.13` in the app bundle |

The build phase `Scripts/embed_python.sh` copies the standard library into `Pythonst3.app/python` and converts extension modules from `.so` into the `.fwork` + `*.framework` layout required by the iOS CPython build. Unlike the upstream helper, it deliberately **does not codesign** nested frameworks, because the IPA must remain unsigned.

At runtime `PythonRuntime` sets `PYTHONHOME` through `PyConfig.home`, sets `argv[0]` to the app executable (required by `AppleFrameworkLoader`), and executes `bootstrap.py`. The bootstrap installs:

- a `sys.stdout` / `sys.stderr` bridge that streams to the SwiftUI console;
- a `builtins.input` bridge that blocks the Python thread and presents a native input field;
- a line trace hook that checks Stop and the execution timeout.

Execution happens on a dedicated serial queue; all Python C API calls take the GIL with `PyGILState_Ensure`.

## Build locally

Requirements: macOS, Xcode 16+, Homebrew, XcodeGen.

```sh
brew install xcodegen
./Scripts/fetch_python.sh
xcodegen generate --spec project.yml
xcodebuild \
  -project Pythonst3.xcodeproj \
  -scheme Pythonst3 \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

The unsigned app is at `build/Build/Products/Release-iphoneos/Pythonst3.app`.

## GitHub Actions

Workflow: `.github/workflows/ios-ipa.yml`

- Triggers: `workflow_dispatch` and pushes to `main` touching app sources, `project.yml`, `Scripts/`, or the workflow.
- Runner: `macos-15`.
- Installs XcodeGen, downloads and checksum-verifies Python-Apple-support, generates the Xcode project, builds Release for `generic/platform=iOS` with signing disabled.
- Validates the `.app` (executable, bundle identifier, embedded framework, stdlib, extension frameworks).
- Packages `Payload/Pythonst3.app` into `Pythonst3-unsigned.ipa`.
- Validates the ZIP structure and bundle identifier again, writes a SHA-256 file, and uploads the `Pythonst3-unsigned-IPA` artifact with 30-day retention.

## Signing boundary

The workflow does not use or request Apple certificates, private keys, provisioning profiles, or signing secrets. It does not upload to App Store Connect.

The produced IPA is **not installable as-is**. ESign must sign the app and its nested code, including `Frameworks/Python.framework`, the Python extension frameworks, and `Frameworks/Pythonst3.app/Frameworks/*.framework`. If ESign reports an unsigned nested binary, enable its option to sign all frameworks / Mach-O files, or re-sign those frameworks before installing.

Python extension modules are shipped as frameworks specifically so a signing tool can sign each binary. They are not a substitute for an Apple Development/Distribution certificate.

## Honest limitations

- CPython runs inside the app process. This is not a hardened sandbox for hostile code.
- `subprocess`, `multiprocessing`, `fork`, shell access, and arbitrary native wheels are not supported.
- Stop/timeouts rely on a Python line trace hook. A C extension or code that disables tracing may not be interrupted immediately.
- Pip installs are not exposed. Only the bundled standard library and pure-Python modules are available. iOS/arm64 wheels would need to be built and packaged separately.
- No unit test target is present yet; the pipeline validates the build and bundle structure. Runtime smoke testing requires a simulator/device.
- The IPA is unsigned. Installation only works after signing with the owner's tool and certificate/profile.
