# Security and Privacy

## Security posture

Pythonst3 executes user-supplied code. Treat every project, package, notebook, AI response and cloud job as untrusted input.

## Local execution

### iOS
- CPython executes embedded inside the app process and within the iOS app sandbox.
- Do not describe this as a hardened sandbox for hostile code.
- Do not promise subprocess, multiprocessing, unrestricted filesystem access or desktop shell behavior.
- Restrict project file access to app-owned workspaces and user-selected Files URLs.
- Make iOS permissions explicit and feature-specific.

### Web
- Run Pyodide in a dedicated Worker, not on the main UI thread.
- Worker isolation improves responsiveness but is not a complete security boundary against browser or resource-exhaustion attacks.
- Limit execution time, output size and memory where technically possible.
- Never use eval to execute untrusted code in the application UI context.
- Sanitize rendered HTML and notebook output.
- Validate ZIP paths, file sizes, MIME types and project manifests.

## Cloud execution (disabled by default)

- No cloud resources are provisioned by this repository's initial setup.
- Never run untrusted code in the API/web server process.
- Require explicit user approval before source files leave the device.
- Use short-lived isolated jobs, non-root execution, quotas and automatic cleanup.
- Network egress disabled by default.
- No host mounts, Docker socket, privileged containers, cloud credentials or shared writable workspaces.
- Enforce per-user rate limits and cost ceilings.
- Present estimated costs and require approval before activation.
- Provide a deletion/retention policy before storing user code.

## AI and secrets

- Never commit API keys, passwords, signing certificates, provisioning profiles or private keys.
- Never put shared secrets in web JavaScript, app assets or public configuration.
- Show users which code/context will be sent to an AI provider.
- Store secrets only in an appropriate protected mechanism; browser-only direct API calls cannot keep a key secret from the device owner.
- Default AI agent mode to read-only.
- Require a diff preview and explicit approval before edits.
- Restrict auto-apply to the active project workspace and provide undo.

## Supply chain

- Pin dependencies and runtime artifacts.
- Review licenses and provenance before bundling.
- Generate and retain a dependency inventory.
- Avoid downloading executable code from untrusted sources at runtime.
- Verify release artifacts and workflow permissions.
