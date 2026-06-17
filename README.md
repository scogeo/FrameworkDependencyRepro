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

## Current Scope

This README is a first-pass summary of the repro and the initial build-artifact analysis. More detailed linker or build-system investigation can be added later if needed.

## Initial Analysis

The framework-linked target appears to be the condition that makes Xcode surface the warnings, but the modules in the warnings are not arbitrary. They correspond to modules re-exported by `swift-dependencies` itself.

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

So the likely trigger is not merely that there are two paths to `SharedModels`. The framework target causes Xcode to turn `SharedModels` from a package object/module artifact into `PackageFrameworks/SharedModels.framework`. The dependency warning appears when Xcode validates that framework artifact's Swift module dependencies.

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

This suggests the warning is not simply Xcode inventing missing dependencies. Xcode's diagnostic is exposed by the framework topology, but the specific missing modules come from the public import/export surface of `swift-dependencies` and `DependenciesMacros`.
