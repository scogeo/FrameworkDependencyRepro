# FrameworkDependencyRepro

This is a small Xcode repro for dependency-scan warnings that appear when the same Swift package target is reached through both a SwiftPM dependency chain and a local framework target.

The intent is to keep the project small enough that the warning source is visible without the extra noise from a production app.

## Project Shape

`repro-package` defines two library products:

- `SharedModels`: imports Point-Free's `Dependencies` and `DependenciesMacros`, and defines a small `@DependencyClient`.
- `AppFeature`: depends on `SharedModels` and `Dependencies`.

The Xcode project defines three targets:

- `SharedFramework`: a local framework target that links `SharedModels`.
- `SPMOnlyApp`: an app target that links only `AppFeature`.
- `SPMWithFrameworkApp`: an app target that links `AppFeature` and also embeds `SharedFramework`.

## Motivation

The framework target represents the kind of boundary needed for Apple integrations such as App Intents, widgets, and extension-facing code. In a real app, most feature and model code may live in Swift packages, but some shared code still needs to be reachable through a framework target so it can be linked into the right bundle.

That creates two paths to the same package module:

```text
SPMOnlyApp -> AppFeature -> SharedModels
```

and:

```text
SPMWithFrameworkApp -> AppFeature -> SharedModels
SPMWithFrameworkApp -> SharedFramework -> SharedModels
```

## Reproduction

Build the SPM-only app:

```sh
xcodebuild -scheme SPMOnlyApp -destination 'generic/platform=iOS Simulator' build
```

This build uses only the SwiftPM dependency chain and does not emit the `SharedModels` missing dependency warnings.

Build the app that also links the framework:

```sh
xcodebuild -scheme SPMWithFrameworkApp -destination 'generic/platform=iOS Simulator' build
```

This build emits warnings like:

```text
warning: 'SharedModels' is missing a dependency on 'DependenciesMacros' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'DependenciesMacros'
warning: 'SharedModels' is missing a dependency on 'IssueReporting' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'IssueReporting'
warning: 'SharedModels' is missing a dependency on 'ConcurrencyExtras' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'ConcurrencyExtras'
warning: 'SharedModels' is missing a dependency on 'Dependencies' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'Dependencies'
warning: 'SharedModels' is missing a dependency on 'Clocks' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'Clocks'
warning: 'SharedModels' is missing a dependency on 'CombineSchedulers' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'CombineSchedulers'
warning: 'SharedModels' is missing a dependency on 'XCTestDynamicOverlay' because dependency scan of Swift module 'SharedModels' discovered a dependency on 'XCTestDynamicOverlay'
```

## Initial Analysis with assitance from OpenAI Codex

### Summary

The warning appears when the project introduces a framework target that also depends on `SharedModels`.

That setup is intentional and ordinary for app projects that need a framework boundary for App Intents, widgets, or extensions:

```text
SPMWithFrameworkApp -> AppFeature -> SharedModels
SPMWithFrameworkApp -> SharedFramework -> SharedModels
```

In this shape, `SharedModels` is reached both through another Swift package target and through a framework target. Xcode detects this and changes how it builds `SharedModels`: instead of leaving it as a package object/module artifact, it packages `SharedModels` as a dynamic package framework under `PackageFrameworks/SharedModels.framework`. This is the strategy Xcode uses so that the app and framework can share one linked copy of the package product rather than creating duplicate symbols.

That dynamic framework packaging step appears to be what makes Xcode validate `SharedModels`' Swift module dependency surface and emit the missing dependency warnings.

### Build Log Evidence

The build logs show that the framework target changes how Xcode materializes `SharedModels`.

When building `SPMOnlyApp`, `SharedModels` is built as a package object/module artifact:

```text
Ld .../SharedModels.build/Objects-normal/<arch>/Binary/SharedModels.o
CreateUniversalBinary .../Build/Products/Debug-iphonesimulator/SharedModels.o
```

When building `SPMWithFrameworkApp`, the `SharedFramework -> SharedModels` dependency causes Xcode to package `SharedModels` as a dynamic package framework:

```text
MkDir .../Build/Products/Debug-iphonesimulator/PackageFrameworks/SharedModels.framework
ProcessInfoPlistFile .../PackageFrameworks/SharedModels.framework/Info.plist
Ld .../SharedModels.build/Objects-normal/<arch>/Binary/SharedModels
```

That linker invocation uses a dynamic library install name:

```text
-dynamiclib
-install_name @rpath/SharedModels.framework/SharedModels
```

The app then embeds that package framework:

```text
Copy .../PackageFrameworks/SharedModels.framework
  .../SPMWithFrameworkApp.app/Frameworks
```

The warning appears in this second build shape, after `SharedModels` has become a package framework artifact.

### Package Surface Evidence

In `swift-dependencies` 1.13.1, `Dependencies` re-exports several transitive dependencies:

```swift
// Sources/Dependencies/Internal/Exports.swift
#if !EXCLUDE_EXPORTS
  #if Clocks
    @_exported import Clocks
  #endif
  #if CombineSchedulers
    @_exported import CombineSchedulers
  #endif
  @_exported import ConcurrencyExtras
  @_exported import IssueReporting
  @_exported import XCTestDynamicOverlay
#endif
```

`DependenciesMacros` also re-exports two transitive dependencies:

```swift
// Sources/DependenciesMacros/Internal/Exports.swift
#if !EXCLUDE_EXPORTS
  @_exported import IssueReporting
  @_exported import XCTestDynamicOverlay
#endif
```

The `SharedModels` target in this repro explicitly depends only on `Dependencies` and `DependenciesMacros`, but its emitted dependency artifacts include the same transitive modules. For example, Xcode emits per-architecture dependency-scan files under the build intermediates directory:

```text
Build/Intermediates.noindex/repro-package.build/Debug-iphonesimulator/SharedModels.build/Objects-normal/<arch>/SharedModels-dependencies-*.json
```

Those files include:

```text
Clocks
CombineSchedulers
ConcurrencyExtras
Dependencies
DependenciesMacros
IssueReporting
XCTestDynamicOverlay
```

So the warning is exposed by Xcode's framework build strategy, but the specific modules reported by the warning line up with modules visible through the current public import/export surface of `swift-dependencies` and `DependenciesMacros`.

### Further Investigation

One experiment was to enable `EXCLUDE_EXPORTS` in a local fork of `swift-dependencies`, because the package already guards the explicit `@_exported import` declarations with that condition. That experiment did not remove all of the warnings. It only removed the warning for `XCTestDynamicOverlay`.

More investigation is needed to understand where the remaining warnings are coming from and whether they can be addressed by tightening imports, changing package traits, or making a broader package-structure change.
