# RepoFeed

RepoFeed is a privacy-first native macOS prototype that builds a private profile from work you permit it to see, then recommends public repositories that could improve your workflow.

## What the MVP does

- Requests read-only access to folders through the standard macOS picker.
- Persists only security-scoped folder bookmarks.
- Inventories eligible files while excluding secrets, credentials, dependencies, build output, system-library folders, and personal-media libraries.
- Reads a diverse, daily-rotating sample of up to 420 code, documentation, and configuration files locally.
- Builds a local profile of technologies, recurring interests, and likely improvement opportunities.
- Finds README files beside `.git` folders or common project manifests for the project feed.
- Presents everything in a familiar three-column social feed with global navigation, a scan composer, opportunity stories, and a trending rail.
- Shows local projects as posts with README previews, profile signals, reactions, and direct links.
- Ranks public GitHub repositories by how well they complement the private profile and explains the likely benefit.
- Shows recently created GitHub repositories with strong star activity.

File contents, filenames, and local paths are not uploaded. GitHub receives only short public search terms such as a technology and an opportunity like `testing` or `documentation`.

## Run during development

```sh
swift run
```

## Test

```sh
swift test
```

## Build the macOS app

```sh
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/RepoFeed.app
```

The packaging script creates an ad-hoc signed, sandboxed app. A distributed release would need an Apple Developer ID signature and notarization.

## Recommendation model

The first version is intentionally explainable. It inventories safe text files, selects a path-hashed sample that rotates daily while maintaining file-type diversity, detects technologies and recurring terms, identifies simple opportunities such as low test-file coverage, and searches GitHub using only those high-level profile signals. “Trending” is a transparent proxy: highly starred public repositories created within the last 45 days.
