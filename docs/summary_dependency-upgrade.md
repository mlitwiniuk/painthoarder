# Dependency upgrade — 2026-10-05

## Runtime and framework

| Component | Previous | Updated |
|---|---|---|
| Ruby | 4.0.5 | 4.0.7 |
| Rails | 8.1.3 | 8.1.4 |
| Bundler | 4.0.12 | 4.0.22 |
| Node | conflicting 22.x pins | 24.21.0 LTS |
| Yarn | conflicting tool configuration | 4.8.1 via Corepack |
| Devise | 4.9.4 | 5.0.4 |
| Pagy | 9.3.4 | 43.7.0 |
| RubyLLM | 1.12.1 | 2.0.0 |
| Puma | 6.6.0 | 8.0.2 |
| SQLite gem | 2.9.1 | 2.9.6 |

Gemfile.lock and yarn.lock are authoritative for all resolved versions. Rails defaults remain 8.1.

## Compatibility work

- Pagy now uses `Pagy::Method`, `limit`, `series_nav`, `info_tag`, and `last`. Removed the custom navigation monkeypatch; DaisyUI styling lives in CSS. Range redirects preserve filters.
- Devise explicitly retains the previous credentials-first secret selection to preserve outstanding tokens.
- RubyLLM 2 uses `parameters`, `with_tools`, `with_provider_options`, and Schematist schemas. Photo identification executes one tool round without an extra model completion. YouTube fallback inserts fileData through a request hook; structured responses use `parsed`.
- Kept Solid Cable 3 and Ransack 4 on current compatible releases. Solid Cable 4 and Ransack 5 should be separate changes with schema/search-behavior review. Ransack now comes from RubyGems instead of a git revision.
- Removed unused TinyMCE and Workbox CLI. Workbox runs after successful esbuild and again after Propshaft fingerprinting. Build errors fail the command. npm's duplicate lockfile is removed.
- Docker pins the same runtimes, excludes development and test gems, and installs Yarn immutably. CI has one SQLite-based workflow with browser, audit, and image-build checks.

## Audit exception

Ruby dependency audit reports no known advisories against the refreshed database. JavaScript audit passes with one explicit exception in `.yarnrc.yml`: braces 3.0.3, GHSA-vfj7-8cjw-p6xm (registry ID 1240992), had no patched release when checked. It is reached through asset tooling using repository-controlled glob patterns, with no request-input path identified. Review/remove the exception when a fix ships; the audit is not an unconditional clean bill of health.

Babel 7 resolutions select patched compatible transitive releases without forcing Workbox onto Babel 8. `--no-deprecations` excludes registry deprecation notices from Yarn's vulnerability gate. One upstream scrollbar/Prism React peer warning remains; the app does not use React.

## Validation and rollout

Verified locally:

- 320 Ruby tests / 924 assertions and 8 headless Chrome tests / 30 assertions passed.
- Zeitwerk eager loading passed; Brakeman reported no high/medium confidence warnings.
- Clean production asset compilation passed; the service-worker manifest includes the final fingerprinted application assets.
- A scratch production boot initialized all four SQLite databases and passed integrity checks, FTS5 search, Solid Queue enqueue, Solid Cache read/write, Solid Cable persistence, libvips resizing, and the HTTP health check.
- New integration/provider/browser tests and the migrated analyzer services pass RuboCop. Full lint still reports 293 offenses, all on pre-existing lines; the CI lint job remains a failing gate until this debt is resolved.

See [the testing guide](guide_testing.md) for reproducible checks. Live AI APIs, S3, Mailgun, and AppSignal are not exercised by local tests. Linux Docker build and remote CI have not been run.

Before deployment:

1. Require a successful Linux amd64 Docker build and CI. Local Docker Desktop was unavailable during the upgrade.
2. Back up all four production SQLite databases consistently (primary, queue, cache, cable), retain the current image/configuration, and rehearse restoring the primary database including FTS5. Do not copy an active SQLite file without accounting for its WAL.
3. In staging, validate image uploads/variants, queued video work, catalog search/pagination, login/reset/confirmation, and the installed PWA with the new asset manifest.
4. Deploy with existing credentials and retained database storage; watch errors, latency, failed jobs, and provider responses. Roll back to the retained image if needed. If subsequent work adds schema changes, reassess database rollback compatibility first.

This change does not deploy or intentionally change application database schemas. Existing lint debt and deeper application refactoring remain separate work.
