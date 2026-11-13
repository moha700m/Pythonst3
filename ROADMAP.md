# PYTHONST3 — Delivery Roadmap

## Product promise

A native iPhone/iPad Python workspace plus a full web companion. Local execution is the default. Cloud Linux execution is a separately approved optional capability, not an assumed dependency.

## Phase 0 — Foundation and feasibility

- [ ] Verify licenses and notices for every dependency.
- [ ] Select a stable Python-Apple-support release and matching Python version.
- [ ] Create Xcode project and minimal CPython embedding proof of concept.
- [ ] Prove print, syntax error, traceback, stdout/stderr and input() bridge.
- [ ] Prove file read/write only within app-owned project workspace.
- [ ] Create web project and run Pyodide smoke tests.
- [ ] Record tested iOS, Xcode, Swift, Python and Pyodide versions.

**Exit criteria:** a native iOS test app and web test page both execute simple Python code and display output, with limitations documented.

## Phase 1 — Native iOS MVP

- [ ] SwiftUI app shell and Arabic RTL navigation.
- [ ] Project list, create/import/export and file explorer.
- [ ] Code editor with syntax highlighting, tabs and search.
- [ ] Embedded CPython runtime manager.
- [ ] Console, stdout/stderr, tracebacks and interactive input.
- [ ] Run / stop / reset controls with safe execution lifecycle.
- [ ] Autosave, crash recovery and project format v1.
- [ ] Package compatibility screen (bundled / installable / unsupported).
- [ ] iPhone and iPad layout/accessibility QA.

**Exit criteria:** a user can create a local project, edit multiple .py files, run supported code, inspect output/errors, close the app and reopen the project.

## Phase 2 — Web Companion MVP

- [ ] React + TypeScript + Vite shell.
- [ ] CodeMirror 6 editor, project explorer and tabs.
- [ ] Pyodide Web Worker runtime.
- [ ] Console and interactive input bridge.
- [ ] IndexedDB project storage and ZIP import/export.
- [ ] Arabic RTL / English LTR and responsive mobile layouts.
- [ ] PWA manifest and tested offline app shell.
- [ ] GitHub Actions CI and static deployment workflow.

**Exit criteria:** supported Python examples run in mobile and desktop browsers, projects persist locally, and deployment is verified.

## Phase 3 — Project portability and parity

- [ ] Shared project format and migrations.
- [ ] Import/export between native and web.
- [ ] Dependency manifest and per-platform compatibility resolver.
- [ ] File conflict handling.
- [ ] Optional user-controlled sync design (not activated by default).

**Exit criteria:** a project can be exported from one client and imported into the other without losing supported files or metadata.

## Phase 4 — AI development tools

- [ ] Provider adapter interface.
- [ ] Explain, generate, debug, refactor and review workflows.
- [ ] Context selection and privacy disclosure.
- [ ] Patch preview, approval, undo and read-only default.
- [ ] API key handling appropriate to each provider.
- [ ] Usage and cost visibility when provider data is available.

**Exit criteria:** AI is clearly optional, no key is embedded in app assets, and file changes require user approval by default.

## Phase 5 — Advanced developer features

- [ ] Notebook-style cells.
- [ ] CSV/JSON viewers and data charts.
- [ ] Plot output support where dependencies are available.
- [ ] Snippets, templates and learning hub.
- [ ] Regex, JSON and encoding utilities.
- [ ] Native iOS integrations with explicit permissions.

## Phase 6 — Optional Cloud Runtime (approval gate)

This phase must remain blocked until the user explicitly approves a provider, a budget, and the security design.

- [ ] Compare provider options and expected cost.
- [ ] Present architecture and maximum spend.
- [ ] Obtain explicit approval before creating resources.
- [ ] Implement isolated ephemeral execution.
- [ ] Add quotas, authentication, network restrictions, cleanup and audit.
- [ ] Add explicit local/cloud execution selector and confirmation.
- [ ] Verify source-code transfer disclosure and deletion policy.

**Exit criteria:** untrusted code runs in reviewed isolation with enforced limits and transparent costs. Never claim this is “any Python code” without compatibility qualification.

## Phase 7 — Release readiness

- [ ] Full automated tests.
- [ ] Real-device iPhone/iPad QA.
- [ ] Safari and major desktop browser QA.
- [ ] Accessibility and localization review.
- [ ] Privacy and security review.
- [ ] App icon, screenshots and release notes.
- [ ] Signed IPA using owner-controlled signing credentials.
- [ ] Website production deployment verification.
- [ ] Backup and rollback procedure.

## Priority guide

| Feature | Priority | Target |
|---|---|---|
| Embedded CPython proof of concept | P0 | Phase 0 |
| iOS editor + local files + run console | P0 | Phase 1 |
| Web editor + Pyodide | P0 | Phase 2 |
| Project import/export parity | P1 | Phase 3 |
| AI assistant and safe patching | P1 | Phase 4 |
| Notebook and data tools | P2 | Phase 5 |
| Cloud Linux runtime | P2 / approval-gated | Phase 6 |

## No-cost rule

Documentation, local development and GitHub Actions configuration may be prepared without provisioning paid infrastructure. Any paid hosting, compute, storage, domain, external AI API, or signing service requires a separate explicit approval first.
