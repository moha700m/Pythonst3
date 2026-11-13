# Technical References and Dependency Review

This document records the primary sources used to choose the initial architecture. Re-check versions, licenses and platform requirements before implementation and release.

## Python embedded on iOS

- [Python documentation: Using Python on iOS](https://docs.python.org/3/using/ios.html) — iOS uses embedded Python within an application; it is not a desktop-style system Python installation.
- [CPython iOS platform README](https://github.com/python/cpython/blob/main/Platforms/Apple/iOS/README.md) — iOS build requirements, Xcode and device/simulator ABI distinctions.
- [BeeWare Python-Apple-support](https://github.com/beeware/Python-Apple-support) — packaged CPython frameworks for Apple platforms.
- [BeeWare Python-Apple-support usage guide](https://github.com/beeware/Python-Apple-support/blob/main/USAGE.md) — integration and initialization guidance for Swift and Objective-C.

## Browser runtime

- [Pyodide documentation](https://pyodide.org/en/stable/) — Python runtime compiled for WebAssembly and browser integration. Validate package support against the exact pinned release.
- [CodeMirror](https://codemirror.net/) — modular code editor suitable for custom mobile-friendly editor interfaces.

## Open-source product reference

- [Pyto repository](https://github.com/ColdGrub1384/Pyto) — reference for a local Python IDE on iOS.
- [Pyto documentation](https://github.com/ColdGrub1384/Pyto/tree/main/docs) — documents its embedded Python approach and iOS integrations.
- [Pyto license](https://github.com/ColdGrub1384/Pyto/blob/main/LICENSE) — repository metadata and checked license file identify MIT. Any code reuse must retain required notices and be reviewed file-by-file; this project currently uses Pyto as a product/architecture reference and does not copy its source.

## Important platform caveats

- [Python documentation: mobile platform limitations](https://docs.python.org/3/library/intro.html#mobile-platforms) — mobile platforms use embedded mode; iOS does not support subprocess/multiprocessing in the conventional way.
- [Apple Foundation Process](https://developer.apple.com/documentation/foundation/process) — desktop process APIs should not be mistaken for an entitlement to launch arbitrary child processes from iOS apps.

## Release pipeline

- [GitHub Pages: custom GitHub Actions workflow](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages) — static web deployment workflow.
- [GitHub Actions: macOS hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners) — macOS build environment for Xcode CI. Check current runner availability and usage limits before relying on it.

## Review policy

No dependency is approved solely because it appears in this list. Before bundling it:
1. Pin a tested release or commit.
2. Inspect the exact license and notices.
3. Verify iOS or browser compatibility.
4. Record package size, update process and security posture.
5. Add a test that proves the claimed feature works.
