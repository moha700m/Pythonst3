# PYTHONST3 — Architecture

## 1. Product topology

~~~text
                   PYTHONST3 PROJECT FORMAT
                  /                         \
        iOS Native App                    Web App / PWA
        SwiftUI                           React + TypeScript
            |                                  |
     Embedded CPython                    Pyodide Runtime
     Python C API                         Web Worker
            |                                  |
     iOS App Sandbox                      Browser Sandbox
            |                                  |
       Local Files                         IndexedDB
                  \                         /
                   Import / Export / Sync
                              |
                 Optional Cloud Runtime
                 Linux container per job
                 (not provisioned by default)
~~~

The native and web clients share a documented project interchange format. They do not pretend to share an identical runtime: each platform has a capability profile and package compatibility registry.

## 2. iOS native application

### UI
- SwiftUI navigation and adaptive layouts.
- Editor surface with syntax highlighting, tabs, search, diagnostics and accessible controls.
- Project explorer backed by app sandbox and document picker / Files integration.
- Console panel implemented in-app; it is not a general operating-system shell.
- Native permission prompts only when a feature needs them.

### Python runtime
- Embed CPython using the official Python embedding API and a compatible Python-Apple-support distribution.
- Prefer BeeWare's documented packaging workflow where suitable.
- Pin the Python minor version and framework release; record build provenance.
- Run interpreter work away from the main UI thread, with explicit serialization if the chosen interpreter build requires it.
- Redirect stdout/stderr to the app console.
- Implement input() using a controlled request/response bridge; do not claim a real terminal stdin.
- Maintain a virtual project working directory mapped to app-owned files.
- Support imports from project files using a controlled sys.path.
- Provide a package capability catalog. Do not promise arbitrary pip installs: binary wheels must be built for iOS/arm64 and satisfy platform constraints.
- Use native bridges for approved iOS APIs rather than assuming desktop modules exist.

### iOS constraints
iOS Python is embedded in an app. No general system Python executable is installed. subprocess, multiprocessing and conventional IPC are not supported for iOS app code. Long-running work and background execution are subject to iOS lifecycle rules. Package availability depends on iOS-compatible builds and app distribution constraints.

## 3. Web application

- React + TypeScript + Vite.
- CodeMirror 6 editor with mobile touch support.
- Pyodide loaded lazily and pinned to a tested release.
- Run Python in a Web Worker; keep the UI responsive.
- Use IndexedDB for projects and runtime metadata.
- Use a virtual filesystem exposed by Pyodide for project files.
- Show package compatibility and installation progress.
- PWA app shell and offline cache only for assets that have actually been cached.
- Do not expose provider secrets in browser bundles.

Pyodide is a browser/WASM Python runtime, not a complete Linux machine. Packages requiring unsupported native binaries, arbitrary OS processes, privileged system access, or unrestricted sockets may not work.

## 4. Shared project model

Initial project interchange format:

~~~json
{
  "format": "pythonst3-project",
  "version": 1,
  "name": "My Project",
  "entrypoint": "main.py",
  "files": [
    { "path": "main.py", "content": "print('Hello')" }
  ],
  "metadata": {
    "pythonTarget": "platform-managed",
    "dependencies": [],
    "createdAt": "ISO-8601",
    "updatedAt": "ISO-8601"
  }
}
~~~

Requirements:
- Validate paths; reject traversal such as ../.
- Preserve UTF-8.
- Never import executable content automatically.
- Support ZIP export/import with size and path limits.
- Store project format version and implement migrations.
- Keep platform-specific runtime settings separate from portable project files.

## 5. Cloud runtime — optional future capability

Not part of the initial deployment. No AWS account, VM, container cluster, database, domain, or paid service should be created automatically.

When explicitly approved, design a provider-neutral execution API:
- One isolated ephemeral container per execution or short-lived session.
- Non-root user, read-only base filesystem, limited writable workspace.
- CPU, memory, wall-clock, output-size and storage quotas.
- Network disabled by default; allowlisted egress only when specifically required.
- No host mounts, Docker socket, cloud credentials or privileged mode.
- Per-user authentication, rate limits, audit metadata and automatic cleanup.
- Explicit cost estimate and hard budget cap before activation.
- User confirmation before sending project files to the cloud.
- No persistence of source code unless the user opts in.

Do not execute untrusted Python directly in the web server process. A container alone is not a complete security boundary; use hardened isolation and a reviewed threat model before production.

## 6. AI architecture

- Provider interface independent from UI.
- User chooses provider/model and supplies credentials.
- Never bundle shared API keys in web or iOS client releases.
- Prefer a separately hosted proxy only if the user approves its deployment and cost.
- Send minimum relevant context; disclose when project files leave the device.
- Agent edits use patch previews, per-file diffs, approval and undo.
- Read-only mode is default; auto-apply is opt-in and restricted to project workspace.

## 7. CI and release

### Web
- npm ci, lint, typecheck, unit tests, production build.
- Deploy static assets to GitHub Pages only after a successful build.
- Configure Vite base path for the repository deployment path.
- Verify deep links, worker assets, WASM assets, PWA manifest and service worker.

### iOS
- Use macOS GitHub Actions runner with Xcode.
- Build simulator target and device archive separately.
- Run unit tests and runtime smoke tests.
- Code signing requires owner-provided Apple signing assets and secrets.
- Never commit certificates, provisioning profiles, private keys or exportOptions secrets.
- Do not label an unsigned archive as a ready-to-install IPA.

## 8. Design language

- Arabic RTL as default; English optional.
- Cyberpunk / hacker-inspired dark UI, high contrast and restrained neon.
- iOS interface should feel native; web interface should adapt to desktop and mobile.
- Code remains LTR while surrounding UI follows locale direction.
- Respect Dynamic Type, VoiceOver, reduced motion, safe areas and keyboard resizing.
