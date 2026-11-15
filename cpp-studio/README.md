# M C++ Studio — GitHub Edition

This folder contains the static GitHub Pages frontend for the Windows C++ build workflow.

## Hosting

- GitHub Pages serves `cpp-studio/index.html`.
- `.github/workflows/deploy-cpp-studio-pages.yml` deploys this folder using GitHub Pages.
- `.github/workflows/build-cpp-windows.yml` builds submitted source on a Windows runner using MSVC x64.

## Important security boundary

GitHub Pages is static hosting. It cannot securely store a repository Personal Access Token, so the website does not call the Actions API with a secret. It encodes source as UTF-8 Base64 and directs the user to run the existing workflow manually in GitHub Actions. Paste the encoded value into `source_b64`.

The Windows runner compiles the EXE; it does not run user executables or stream an interactive Windows desktop into the browser.

## Enable Pages

In repository Settings → Pages, set Build and deployment source to **GitHub Actions**. Then merge the deployment workflow to `main` or run it manually.
