# Producer paint catalog refresh

Producer refreshes automatically publish confident additions, matches and updates every day. Administrators only see exceptions; leaving them unresolved does not stop other paints updating. Every fetch saves its source snapshot, decisions and publication method for inspection. Paints are never automatically deleted.

## Coverage

| Producer | Public source | Supported singles |
| --- | --- | --- |
| Monument Hobbies | [Paint singles JSON](https://monumenthobbies.com/collections/paint-singles/products.json) | Pro Acryl, Signature Series, 1-Step |
| The Army Painter | [Store products JSON](https://thearmypainter.com/products.json) | Recognized Warpaints, Fanatic, Speedpaint 2.0, Air, Historical, John Blanche Masterclass SKUs |

The client paginates these unauthenticated storefront endpoints. These are not contractual producer APIs; changes to their format or product naming may require adapter updates. Fixed HTTPS hosts, timeouts, response-size limits, bounded retries for HTTP 429/5xx, and pagination checks limit failed fetches. An empty recognized catalog fails the batch. A drop exceeding 20% from the last successfully processed automatic batch pauses automatic publishing. Initial automation can use an earlier preview as its baseline. Blocked or partially failed automatic batches never become the baseline, so a repeatedly truncated feed stays paused. Ordinary missing products do not stop healthy updates.

Sets, bundles, multiple-variant packaging, other vendors, primers, mediums and other auxiliaries are excluded. Unrecognized lines/SKUs are listed with reasons for review, including Monument AMP paints in this first version. Inspect exclusions when a producer launches a range. A sold-out listing remains a paint; stock state and absence never imply discontinuation.

Vallejo, AK Interactive and Citadel need separate adapters. RGB values are not extracted from product photographs or inferred from names.

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
```

These commands publish confident changes and print the history URL and counts. Set `DRY_RUN=1` before either command to save a preview without publishing. Older snapshots created before automation was introduced remain previews. Run with the intended Rails environment and the repository's pinned Ruby runtime.

## Matching and preservation

The producer's variant ID becomes the stable identity after linking. Subsequent producer name/SKU changes follow that identity automatically. A name edited locally after linking is preserved and held for a decision.

Initial matching uses unique SKU/code or normalized names. Automatic linking requires matching code and name, or a recognized matching paint family; name-only matches with conflicting real producer codes are held. Explicit family mappings accommodate legacy subcategories (for example Fanatic effects stored under Fanatic Wash). Identical names in explicitly different families become separate paints. Unknown legacy ranges, duplicate candidates and conflicting identities remain exceptions. No fuzzy or AI-generated match is automatically accepted.

Family mappings live in `PaintCatalog::Identity`; new adapters must define their supported families. Application rechecks current database identities and paint baselines so a stale proposal cannot overwrite a later edit.

Applying an existing match can update its name and producer metadata. It preserves the Paint ID, local code, product line, RGB/LAB, collections and project links. Producer SKUs and ranges remain available separately in the saved payload; existing local range membership is deliberately not migrated automatically. New paints use the adapter's canonical range. Historical names/codes are stored as aliases for provenance, but are not searched by FTS yet.

Only the latest successful batch for a producer can be applied, for up to 14 days. Changes to a matched paint after comparison require a new fetch. Applying the same entry twice is harmless. Database uniqueness constraints prevent two active runs per producer and multiple producer identities claiming one paint for that source.

Fetches update last-seen timestamps for linked identities. Missing linked paints generate a warning and keep their existing records. No automatic retirement, deletion or range removal occurs.

## Unknown swatches

New producer paints can immediately be searched and added to collections with RGB, hex and LAB all NULL. They display a striped placeholder and are excluded from color matching, video color alternatives and the color wheel until a trusted swatch is supplied. Existing colors retain `legacy_dataset` provenance; assigning RGB to an unknown swatch marks it `manual`.

There is no new swatch editor in this slice. A maintainer can assign verified RGB through `Paint#update!` using all three channels; callbacks calculate hex and LAB. Do not use `update_all` for color changes, invent approximate RGB, or replace trusted existing colors with product-image samples.

## Failures and operation

Failed fetches publish no comparisons. Their error is shown in the admin history and reported through Rails' error reporter. Enqueue failures release the source so it can be retried. On its next daily run, the scheduler expires queued/running fetches older than two hours and queues replacements. An administrator can also cancel a fetch. Both paths prevent an old worker from publishing a cancelled result. Failed automatic publication keeps already completed entries and reports its error separately from fetch status; the next refresh retries unresolved work against fresh data.

Snapshots are retained in the application database for inspection. This version has no retention job or new external alert integration. The dashboard shows fetch/publication failures and held comparisons across producers. There is no new email or push notification. Connect the existing Rails error reporter to operational monitoring for failures. Disable the recurring entry in `config/recurring.yml` to stop scheduled publishing; `DRY_RUN=1` remains available for manual diagnosis.

For validation, run the normal Rails suite and `test/system/paint_catalog_system_test.rb`. Tests exercise authorization, failed/empty fetches, pagination, retries, matching conflicts, stale reviews, automatic publication, persistent dismissals, resumable failures, stale-job recovery, preserved user collections, and unknown-color rendering/matching. Live storefront verification is separate from these stubbed regression tests.

A transactionally rolled-back rehearsal against the producer snapshots fetched on 2026-10-05 processed 686 of 695 recognized products automatically (98.7%): 156 additions and 530 existing links. Nine were held: six Monument legacy range/name conflicts and three Army Painter duplicate records. Repeating both feeds produced no additional paints. These figures describe the local snapshot and database, not a production deployment or a guarantee for later feeds.
