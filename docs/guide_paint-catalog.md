# Producer paint catalog refresh

Producer refreshes automatically publish confident additions, matches and updates every day. Administrators only see exceptions; leaving them unresolved does not stop other paints updating. Every fetch saves its source snapshot, decisions and publication method for inspection. Paints are never automatically deleted.

## Coverage

| Producer | Public source | Supported singles |
| --- | --- | --- |
| Monument Hobbies | [Paint singles JSON](https://monumenthobbies.com/collections/paint-singles/products.json) | Pro Acryl, Signature Series, 1-Step |
| The Army Painter | [Store products JSON](https://thearmypainter.com/products.json) | Recognized Warpaints, Fanatic, Speedpaint 2.0, Air, Historical, John Blanche Masterclass SKUs |
| WarHub open catalog | [Manifest](https://warhub.github.io/warhub-catalog/manifest.json), then individual brand partitions | 19 additional brands; color paints with validated optional swatches |

The direct clients paginate the unauthenticated storefront endpoints. These are not contractual producer APIs; changes to their format or product naming may require adapter updates. Fixed HTTPS hosts, timeouts, response-size limits, bounded retries for HTTP 429/5xx, and pagination checks limit failed fetches. An empty recognized catalog fails the batch. A drop exceeding 20% from the last successfully processed automatic batch pauses automatic publishing. Initial automation can use an earlier preview as its baseline. Blocked or partially failed automatic batches never become the baseline, so a repeatedly truncated feed stays paused. Ordinary missing products do not stop healthy updates.

Sets, bundles, multiple-variant packaging, other vendors, primers, mediums and other auxiliaries are excluded. Unrecognized lines/SKUs are listed with reasons for review, including Monument AMP paints in this first version. Inspect exclusions when a producer launches a range. A sold-out listing remains a paint; stock state and absence never imply discontinuation.

WarHub covers **AK Interactive, AK Real Color, AMMO by Mig Jimenez, Citadel Colour, Coat D'Armes, Foundry, Green Stuff World, Humbrol, Kimera Kolors, Mission Models, Mr Hobby, P3, Reaper, Scale75, Tamiya, Turbo Dork, Two Thin Coats, Vallejo and Warcolours**. Monument and Army Painter remain on their direct feeds; a second source cannot compete to update those same brands.

The registry in `PaintCatalog::Sources` maps WarHub names to existing application brands, including AK, A K R C, Mig, P3, Coat D Armes and Duncan. It deliberately does not auto-enable unknown future partitions. Source keys use the `warhub_` prefix, such as `warhub_vallejo`, `warhub_citadel_colour` and `warhub_two_thin_coats`.

WarHub is a community catalog, not an authoritative producer feed. Each refresh reads the manifest and its brand partition, verifies SHA-256, byte size, record count, schema 1.1, brand and release consistency, and retains the release metadata with the raw snapshot. A publication race or integrity mismatch fails the entire fetch. The adapter only accepts `category: paint` and `role: colour`; primers, mediums, pigments, varnishes, textures and colorless records are excluded. Explicitly discontinued color paints remain available for historical collections; no existing paint is retired or deleted.

WarHub data is MIT licensed. The required notice is included in [LICENSES/warhub-catalog.txt](../LICENSES/warhub-catalog.txt); upstream provenance is documented in the [WarHub repository](https://github.com/WarHub/warhub-catalog). Swatches are catalog data, not measurements or values extracted from product photographs.

## Setup and use

1. Back up the database and run `bin/rails db:migrate`.
2. Run the Solid Queue worker/scheduler (`bin/jobs`). Production schedules an automatic refresh every day at 05:00 in the scheduler's configured timezone.
3. Sign in as an administrator and choose **Producer catalog updates** in the account menu, or open `/admin/paint_catalog_runs`.
4. Routine updates need no action. **Refresh now** starts the same automatic process immediately.
5. The cross-brand exceptions list contains only held changes. Resolve a duplicate by choosing its existing paint, explicitly create a separate paint, or dismiss the listing. Existing IDs, collections and swatches remain intact while an exception is unresolved.
6. A resolved identity is remembered. Dismissals carry forward while meaningful producer details remain unchanged, so the same decision is not requested every day. Changed details reopen a dismissal.
7. Manual bulk approval remains available for up to 50 entries, with atomic application and warning acknowledgement. Automatic publishing uses individual transactions to avoid locking SQLite for an entire catalog; a retry resumes remaining entries after an unexpected failure.

For a synchronous fetch without a queue worker, run each producer in a separate command:

```sh
bin/rails 'paint_catalog:fetch[monument]'
bin/rails 'paint_catalog:fetch[army_painter]'
bin/rails 'paint_catalog:fetch[warhub_vallejo]'
DRY_RUN=1 bin/rails 'paint_catalog:fetch[warhub_citadel_colour]'
```

These commands publish confident changes and print the history URL and counts. Set `DRY_RUN=1` before either command to save a preview without publishing. Older snapshots created before automation was introduced remain previews. Run with the intended Rails environment and the repository's pinned Ruby runtime.

## Matching and preservation

The producer's variant ID becomes the stable identity after linking. Subsequent producer name/SKU changes follow that identity automatically. A name edited locally after linking is preserved and held for a decision.

Initial matching uses unique SKU/code or normalized names. Automatic linking requires matching code and name, or a recognized matching paint family; name-only matches with conflicting real producer codes are held. Explicit family mappings accommodate legacy subcategories (for example Fanatic effects stored under Fanatic Wash). Identical names in explicitly different families become separate paints. Unknown legacy ranges, duplicate candidates and conflicting identities remain exceptions. No fuzzy or AI-generated match is automatically accepted.

Family mappings live in `PaintCatalog::Identity`. WarHub normally uses its named range as the family, with explicit aliases for the legacy Duncan Wave 1/2/3 ranges. Code-free listings match by normalized name and range rather than treating a name as a globally unique SKU. Product-code punctuation is normalized; Reaper numeric leading zeros are ignored for matching.

Bottle-size suffixes are ignored for candidate discovery, so a second packaging identity is held rather than added as a new color. Simultaneous entries with distinct product codes sharing a name/range/volume are treated as explicit catalog variants, even when approximate swatches are identical (for example Vallejo True Metallic Metal); codes keep them separate. Uncoded existing paints that could match multiple such variants remain exceptions. Application rechecks current database identities and paint baselines so a stale proposal cannot overwrite a later edit.

Applying an existing match can update its name and producer metadata. It preserves the Paint ID, local code, product line, RGB/LAB, collections and project links. Producer SKUs and ranges remain available separately in the saved payload; existing local range membership is deliberately not migrated automatically. New paints use the adapter's canonical range. Historical names/codes are stored as aliases for provenance, but are not searched by FTS yet.

Only the latest successful batch for a producer can be applied, for up to 14 days. Changes to a matched paint after comparison require a new fetch. Applying the same entry twice is harmless. Database uniqueness constraints prevent two active runs per producer and multiple producer identities claiming one paint for that source.

Fetches update last-seen timestamps for linked identities. Missing linked paints generate a warning and keep their existing records. No automatic retirement, deletion or range removal occurs.

## Unknown swatches

When a WarHub paint has a valid six-digit hex swatch, new paints and existing paints with unknown colors receive its RGB value and `warhub` provenance; model callbacks derive hex and LAB. Known legacy or manual swatches are never overwritten, including when WarHub later changes its value. Editing RGB normally marks the swatch `manual`.

Paints whose source has no swatch can immediately be searched and added to collections with RGB, hex and LAB all NULL. They display a striped placeholder and are excluded from color matching, video color alternatives and the color wheel until a trusted swatch is supplied. Existing colors retain `legacy_dataset` provenance; assigning RGB to an unknown swatch marks it `manual`.

There is no new swatch editor in this slice. For swatches unavailable from the catalog, a maintainer can assign verified RGB through `Paint#update!` using all three channels; callbacks calculate hex and LAB. Do not use `update_all` for color changes, invent approximate RGB, or replace trusted existing colors with product-image samples.

## Failures and operation

Failed fetches publish no comparisons. Their error is shown in the admin history and reported through Rails' error reporter. Enqueue failures release the source so it can be retried. On its next daily run, the scheduler expires queued/running fetches older than two hours and queues replacements. An administrator can also cancel a fetch. Both paths prevent an old worker from publishing a cancelled result. Failed automatic publication keeps already completed entries and reports its error separately from fetch status; the next refresh retries unresolved work against fresh data.

Snapshots are retained in the application database for inspection. This version has no retention job or new external alert integration. The dashboard shows fetch/publication failures and held comparisons across producers. There is no new email or push notification. Connect the existing Rails error reporter to operational monitoring for failures. Disable the recurring entry in `config/recurring.yml` to stop scheduled publishing; `DRY_RUN=1` remains available for manual diagnosis.

For validation, run the normal Rails suite and `test/system/paint_catalog_system_test.rb`. Tests exercise authorization, failed/empty fetches, pagination, retries, matching conflicts, stale reviews, automatic publication, persistent dismissals, resumable failures, stale-job recovery, preserved user collections, and unknown-color rendering/matching. Live storefront verification is separate from these stubbed regression tests.

A transactionally rolled-back rehearsal against the producer snapshots fetched on 2026-10-05 processed 686 of 695 recognized products automatically (98.7%): 156 additions and 530 existing links. Nine were held: six Monument legacy range/name conflicts and three Army Painter duplicate records. Repeating both feeds produced no additional paints. These figures describe the local snapshot and database, not a production deployment or a guarantee for later feeds.

WarHub integration checks include checksum/release mismatches, malformed or cross-brand rows, names without codes, range aliases, packaging conflicts, distinct coded variants, color provenance and preserving known swatches. The live Vallejo client and every configured partition were verified against release 2026.10.4; full publishing was rehearsed against a separate SQLite copy so the working catalog was not changed.

The expanded isolated rehearsal processed 7,213 color-paint records from those 19 partitions: 7,173 applied automatically (99.4%), with 40 duplicate or conflicting identities held. It added 958 paints: 748 with WarHub swatches and 210 without supplied swatches. Existing RGB values, local codes, ranges and collection/project records remained unchanged. These are snapshot-specific rehearsal results; working and production catalogs were not published by this verification.
