# GitHub Actions build on `macos-latest`

This repository now includes a ready workflow:

```text
.github/workflows/ios-libbox-macos.yml
```

## What it does

- runs on `macos-latest`
- selects Xcode on the hosted macOS runner
- installs Go and `gomobile`
- builds `ios/Frameworks/Libbox.xcframework`
- uploads `Libbox.xcframework` as a workflow artifact
- if a real iOS host project exists later (`ios/Runner.xcodeproj` or `ios/Runner.xcworkspace`), it also tries a simulator `xcodebuild` without codesign

## How source resolution works

The workflow prefers these layouts already committed in the repo:

```text
sing-box-testing/
sing-box-testing/sing-box-testing/
```

If neither exists, it clones the official `SagerNet/sing-box` repository into the runner temp directory and uses that source tree to build `Libbox.xcframework`.

You can optionally pass a manual ref/tag/sha in **Run workflow** as `sing_box_ref`.

## What you get from Actions

After the job succeeds, download the artifact:

```text
Libbox.xcframework-macos
```

This artifact should contain:

```text
ios/Frameworks/Libbox.xcframework
```

## Honest limitation

This patch archive still does **not** contain a full generated Xcode host project (`Runner.xcodeproj` / `Runner.xcworkspace`).

So the workflow can reliably build the Apple framework now, but a full app build will only run automatically after a real iOS host project is committed into the repository.

## Recommended next step

After you place the project in GitHub:

1. push this patched repo
2. open **Actions**
3. run **ios-libbox-macos**
4. download `Libbox.xcframework-macos`
5. commit or attach the built framework into your real iOS project flow
