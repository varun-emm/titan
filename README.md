# Titanic 1912 — Web and Mobile Release

Public GitHub Pages target: **https://varun-emm.github.io/titan/** (becomes live **only after publishing**).

This release retains the original procedural character, 17 interior kits, textures, lighting, deck travel, teleport and cinematic grain. No itch.io character files or animations are included.

## Controls

- Desktop: WASD, mouse-look, Shift run; M teleport; G map; V camera; E/Q stairs; T tour; N grain; L lighting.
- Touch/mobile: lower-left virtual joystick to move, drag right-hand area to look. Top-right buttons: MAP, TELEPORT, VIEW, TOUR, UP, DOWN.
- Web build uses single-threaded Compatibility rendering for ordinary GitHub Pages. Mobile browser performance varies significantly; on older phones use a recent browser and landscape orientation.

## Publish to the requested URL

1. On GitHub create a **public** repository named `titan` under `varun-emm`. Initialize it with a README.
2. Upload this source tree (including `.github/workflows/deploy.yml` and `export_presets.cfg`) to its `main` branch.
3. In Settings → Pages, select **GitHub Actions** as the build/deployment source.
4. The workflow downloads Godot 4.7.2 and its export templates, exports a Web build, and deploys to `https://varun-emm.github.io/titan/`.
5. Review the Actions logs if import/export fails. The workflow and Godot export are **unverified here** because no Godot runtime or Internet access is available in this execution environment.

## Important limitations

The GitHub connector currently supports editing existing repositories, but not creating them. The repository must be created manually before the assistant can publish to it. No URL is live until a deployment actually succeeds. Web mobile support uses Godot WebGL2; iOS/mobile rendering performance and compatibility are not guaranteed.
