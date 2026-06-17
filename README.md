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

This README is a first-pass summary of the repro. If useful, the next step is to add deeper analysis from build logs and build artifacts showing why the framework-linked target causes Xcode to scan `SharedModels` differently.
