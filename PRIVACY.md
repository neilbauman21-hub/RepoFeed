# RepoFeed privacy and architecture

RepoFeed is designed as a single-user, local-first desktop application.

## No RepoFeed server

RepoFeed has no application backend, hosted database, account system, telemetry collector, advertising system, or inter-user functionality. It does not create a network of people. The social-feed design is only an interface for repositories, models, datasets, Spaces, and local project activity.

Public discovery requests travel directly from the macOS app to:

- `api.github.com` for public repository metadata.
- `huggingface.co/api` for public Hub metadata.

RepoFeed does not proxy either service through infrastructure controlled by the project.

## Local data

The following remain on the Mac:

- Security-scoped folder permissions.
- File inventory and samples.
- Builder profile and inferred opportunities.
- Cached recommendation metadata.

File contents, filenames, and local paths are not sent to GitHub or Hugging Face. Only broad derived searches such as `code`, `embedding`, `Swift`, or `testing` are sent.

## Open-source-only discovery

RepoFeed requires an explicit license identifier from an internal allowlist. Items with a missing license, gated access, private visibility, source-available restrictions, research-only terms, or non-commercial restrictions are excluded.

License metadata can be incorrect upstream. Users should still verify a project's license before redistribution or commercial use.
