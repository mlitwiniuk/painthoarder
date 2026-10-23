# PaintHoarder redesign screenshot reference

Captured **23 October 2026** from the running local application using the Codex in-app browser.

Open the [browsable screenshot gallery](../design/redesign-reference/2026-10-23/index.html) to filter 31 captures by workflow and open original images. The [JSON inventory](../design/redesign-reference/2026-10-23/screenshots.json) records each screen's route, captured state, purpose, image dimensions, and design question.

## Scope and capture conditions

- Screens 01–26 show the signed-in application at `http://127.0.0.1:3000`. The existing account has 3 owned paints, no wishlist entries, and one project. The public video library contains one analyzed tutorial.
- Screens 27–31 show the signed-out landing page and authentication forms at `http://localhost:3000`, using the same local app with a separate browser session.
- Captures use the existing light theme and native desktop viewports. Original JPEGs are unchanged; dimensions are recorded per image. Most app screens are 1528 × 1309 pixels, modal captures are 1539 × 1318, and public entry captures are 1269 × 714 or 1280 × 720. These are image dimensions, not a claim about CSS viewport or device pixel ratio.
- Long pages are represented by selected viewports. Screen 09 is slightly scrolled to include photo-upload controls; 14 shows comparison results; 28–29 show lower landing-page sections. The product carousel in 28 contains existing promotional screenshots, which are not evidence of the current live UI.
- Search, navigation, tabs and form expansion were exercised. No paints, projects, updates or accounts were saved; no photos were uploaded and no AI analysis jobs were started. The signed-in browser was returned to its dashboard.
- Administration is excluded at the user's request. This is a visual inventory and planning reference, not a complete functional or accessibility audit. Counts and content describe this local dataset, not production usage.

## User journeys represented

| Journey | Captures | Important interaction states |
| --- | --- | --- |
| Understand the product → register or sign in → dashboard | 27–31, 01 | Public messaging, product preview, community counts, blank authentication forms, returning-user overview |
| Browse collection → filter → inspect → edit | 02–07, 10 | Populated grid, expanded filters, empty wishlist, owned paint detail, preselected wizard, status/notes/purchase details, color wheel |
| Import a collection | 08–09 | Text and photo entry, instructions, examples, file constraints |
| Discover paint → compare alternatives → add | 11–17, 06–07 | Search results, brand directory, brand lines, line grid, unowned paint detail, cross-brand alternatives |
| Discover projects → view progress → create/update | 18–22 | Public and personal feeds, owner view, timeline photos, update modal, project visibility selection |
| Find tutorial → inspect extracted paints → substitute brands | 23–26 | Public library, matched/unmatched paints, timestamps, alternatives, URL submission and daily allowance |

## Observations to resolve during redesign

These observations come from the captured screens. Their effect on usability still needs validation with users.

1. **Establish one navigation and visual language.** Catalogue pages use a large gradient banner, collection pages use large headings and stat cards, and projects/videos use a compact toolbar. Personal projects are under Gallery → Mine. Sign-in and registration use a different wordmark from the app header. Decide the top-level information architecture before polishing individual screens. Evidence: 01–02, 11, 18, 23, 30–31.
2. **Make paint discovery and comparison consistent.** Collection/catalogue search is hidden behind Filters, while product-line pages expose color chips. Catalogue, collection and similarity results use related but different card layouts and actions. Long names truncate on the product-line grid. Preserve brand, product line, status and paint identity in the shared design. Evidence: 02–03, 11–17.
3. **Give statuses a consistent meaning.** Wishlist is pink in collection tabs, yellow on paint detail actions and outlined in the edit wizard. Owned styling also varies between green badges and the blue selected wizard tile. Specify text, icon and color behavior together. Evidence: 02, 04–07, 13.
4. **Reduce friction in collection maintenance.** Editing an existing paint opens the selection wizard; the captured preselection advances to step 3 before status/notes on step 4. The empty wishlist leads to a generic “Add Your First Paint” action. Evaluate a direct details edit and clearer entry actions. Evidence: 04, 06–07.
5. **Design import as input → review → commit.** Current input screens devote substantial space to pros/cons and instructions. Matching, ambiguity resolution, processing and failure states are essential follow-up screens before estimating this flow. Evidence: 08–09; result states were not captured.
6. **Improve guidance in specialized tools.** The color wheel has no visible legend/instructions in the captured state. Paint alternatives expose ΔE terminology; video alternatives add small chips to a long, narrow list. Clarify how to use these results and what a match means. Evidence: 10, 14, 24–25.
7. **Keep creation and visibility decisions clear.** Projects and videos use a prominent plus icon without a visible text label on desktop. New projects default to Public in the captured form; the update form explains that it inherits project visibility and only searches paints in the collection. Preserve these dependencies in the redesigned flow. Evidence: 18, 20–23.
8. **Align public messaging with the actual experience.** The local landing page shows 5 painters but also says “Join thousands”; its embedded preview uses older navigation. The dashboard says more social features are coming soon while Gallery already exposes community projects. Audit claims and refresh product imagery as part of launch work. Evidence: 01, 27–29. Production content was not checked.

## Suggested redesign work packages

Use this sequence to create and estimate design tickets. It proposes dependencies and handoff scope; it does not assign dates or imply measured effort. Confirm product priorities, mobile requirements and missing states before committing a calendar.

| Order | Work package | Screens | Dependency | Design handoff should include |
| --- | --- | --- | --- | --- |
| 1 | Shared foundations and navigation | All, especially 01–03, 11, 18, 23, 30 | Product priorities | Navigation map, typography/spacing, status semantics, buttons, cards, form fields, dialogs, responsive rules and focus states |
| 2 | Core collection and paint discovery | 01–07, 10–17 | Shared foundations | Dashboard, collection and catalogue templates, filters, detail/comparison layouts, add/edit flow, empty/no-results states, long-name handling |
| 3 | Bulk import | 08–09 plus missing review states | Core paint selection and status patterns | Text/photo entry, processing, candidate selection, ambiguous/missing matches, duplicate handling, confirmation and recovery |
| 4 | Projects and community | 18–22 | Shared navigation, media and paint-selection patterns | Personal/public feeds, project timeline, photo viewing, create/edit/update forms, visibility explanations, empty and failed-upload states |
| 5 | Video analysis and alternatives | 23–26 | Paint discovery and comparison | Library, URL input, usage limit, processing/failure, matched/unmatched results, alternate brands, long result lists and mobile behavior |
| 6 | Public entry and onboarding | 27–31 | Final navigation/brand; stable redesigned screens | Landing page, refreshed screenshots/copy, sign-in/register/recovery, validation and confirmation, first-run onboarding |
| 7 | Cross-flow validation and handoff | All | Packages above | Desktop/mobile prototypes, keyboard and contrast checks, realistic large datasets, annotated interaction states and implementation acceptance criteria |

Collection and catalogue are the recommended first feature package because they supply the paint selection and status patterns used by imports, projects and videos. Reorder later packages using actual product goals and usage evidence.

## Follow-up evidence before final estimates

| Missing evidence | Why it matters |
| --- | --- |
| Mobile/tablet and drawer navigation | Desktop captures do not establish responsive behavior, touch targets or dialog fit. |
| Dark theme, keyboard focus and accessible alternatives | The current reference covers light-theme screenshots, not contrast measurements or assistive-technology usability. |
| Completely empty and large collections; no search results; long labels | The signed-in sample contains only three paints. |
| Add wizard from a blank selection, validation and save feedback | The captured wizard uses an existing paint and was not submitted. |
| Text-match review and photo-recognition results | No import or recognition request was submitted. |
| Project edit, private/link-only views, image viewer, upload failures | Captured project detail is a public project viewed by its owner; viewing permissions were not tested. |
| Video queued/processing/failed/limit-reached states and correction UI | Existing successful results were observed; no new analysis job was started. |
| Authentication recovery, confirmation, invalid input and first-run onboarding | Only blank sign-in and registration forms were captured. |

## Screenshot inventory

The links below open the original screenshots. For visual comparison, use the gallery linked above.

| ID | Screen | State / redesign focus |
| --- | --- | --- |
| 01 | [Dashboard](../design/redesign-reference/2026-10-23/screenshots/01-dashboard.jpg) | Signed in; 3 collected paints, 0 wishlist paints; login notice dismissed. Decide which action deserves priority; large empty areas compete with stacked statistics and activity cards. |
| 02 | [My Collection](../design/redesign-reference/2026-10-23/screenshots/02-collection.jpg) | All tab; populated collection with 3 owned paints. Preserve clear status labels while harmonizing card size, swatch treatment and metadata. |
| 03 | [Collection filters](../design/redesign-reference/2026-10-23/screenshots/03-collection-filters.jpg) | Filters expanded: search, brand, product line, color. Search is behind Filters. Consider making frequent search visible and defining applied-filter feedback. |
| 04 | [Wishlist empty state](../design/redesign-reference/2026-10-23/screenshots/04-wishlist-empty.jpg) | Wishlist tab; no wishlist paints. The wishlist-specific message leads to a generic Add Your First Paint action; make the intended status clear. |
| 05 | [Collected paint detail](../design/redesign-reference/2026-10-23/screenshots/05-collection-paint-detail.jpg) | Owned paint; color values, status actions, community counts, similar paints. Separate status changes, editing and removal; maintain a consistent relationship to the catalogue detail. |
| 06 | [Edit paint wizard](../design/redesign-reference/2026-10-23/screenshots/06-edit-paint-wizard.jpg) | Step 3 of 4 after asynchronous preselection; existing paint shown; no changes submitted. This edit flow preselects values and advances to step 3. Assess whether every edit needs the selection journey. |
| 07 | [Paint status and purchase details](../design/redesign-reference/2026-10-23/screenshots/07-edit-paint-details.jpg) | Step 4 of 4; optional purchase details expanded; form not saved. Use consistent status colors and clearly label optional fields; review the dollar-only price presentation. |
| 08 | [Bulk text import](../design/redesign-reference/2026-10-23/screenshots/08-import-text.jpg) | Text Import tab; empty form. The long pros/cons introduction competes with the task. Prototype a shorter input-to-review journey. |
| 09 | [Bulk photo import](../design/redesign-reference/2026-10-23/screenshots/09-import-photo.jpg) | Photo Import tab; slightly scrolled so upload controls fit; no photo uploaded. Keep examples, upload limits and guidance; include processing, partial recognition and correction states in scope. |
| 10 | [Collection color wheel](../design/redesign-reference/2026-10-23/screenshots/10-color-wheel.jpg) | Three collected paints plotted in the color visualization. The captured wheel has no visible legend or explanatory instructions; plan orientation and a nonvisual equivalent. |
| 11 | [Paint catalogue](../design/redesign-reference/2026-10-23/screenshots/11-paint-catalog.jpg) | Default name sort; 12,565 paints, 34 brands, 221 product lines. Unify catalogue and collection card patterns, including owned indicators, add affordances and long names. |
| 12 | [Catalogue search results](../design/redesign-reference/2026-10-23/screenshots/12-catalog-search.jpg) | Filters expanded; 3 Mephiston Red matches across different product lines. Search returns the same name in Air, Spray and Base. Product line must remain easy to compare. |
| 13 | [Catalogue paint detail](../design/redesign-reference/2026-10-23/screenshots/13-catalog-paint-detail.jpg) | Unowned paint; quick collection actions; color metadata and similar-paint section. Maintain a strong primary action and align status colors with the collection and wizard. |
| 14 | [Similar paint comparison](../design/redesign-reference/2026-10-23/screenshots/14-similar-paints.jpg) | Scrolled to Closest match results with Vallejo selected and ΔE labels. Explain match meaning in plain language and preserve side-by-side identification. This viewport is scrolled below the section heading. |
| 15 | [Brand directory](../design/redesign-reference/2026-10-23/screenshots/15-brands-directory.jpg) | Alphabetical directory of 34 brands. Resolve naming, logo sizing and hierarchy across directory cards; avoid losing catalogue search context. |
| 16 | [Brand product lines](../design/redesign-reference/2026-10-23/screenshots/16-brand-detail.jpg) | Citadel Colour landing page; active and discontinued lines. Distinguish discontinued lines clearly and retain useful brand context. |
| 17 | [Product line paint grid](../design/redesign-reference/2026-10-23/screenshots/17-product-line.jpg) | Citadel Base line; swatch cards and paint names. Color chips use a different filter pattern from catalogue dropdowns. Several long paint names truncate. |
| 18 | [Community gallery](../design/redesign-reference/2026-10-23/screenshots/18-community-gallery.jpg) | Public project feed with author, update count, photo previews and actions. Make creating a project discoverable; the desktop action is an unlabeled plus icon. |
| 19 | [Project timeline](../design/redesign-reference/2026-10-23/screenshots/19-project-detail.jpg) | Public WHQ: DW project viewed by its owner; 2 updates and 5 photos. Review repeated project titles and the relationship between large photo layouts, update text and paints used. |
| 20 | [Create project update](../design/redesign-reference/2026-10-23/screenshots/20-project-update-form.jpg) | Add Update modal; photos, title, description and paints used; not submitted. The modal introduces a collection dependency. Keep privacy context and support search/attachment states. |
| 21 | [My projects](../design/redesign-reference/2026-10-23/screenshots/21-my-projects.jpg) | Personal project feed with one existing project. Clarify Mine/All navigation and keep create, edit and sharing actions consistent. |
| 22 | [Create project](../design/redesign-reference/2026-10-23/screenshots/22-new-project.jpg) | Empty project form with public visibility selected by default; not submitted. Public visibility is selected by default in this capture. Make the choice and its audience understandable before submission. |
| 23 | [Public video library](../design/redesign-reference/2026-10-23/screenshots/23-video-library.jpg) | One analyzed tutorial with 25 paints. Unify library navigation with projects; sparse libraries need a useful start action. |
| 24 | [Video analysis results](../design/redesign-reference/2026-10-23/screenshots/24-video-analysis.jpg) | 25 extracted paints: 19 matched, 6 unmatched; video embed and timestamps. The long narrow results column mixes matched/unmatched data, timestamps and icon actions. Prototype clearer scan and review behavior. |
| 25 | [Video paint alternatives](../design/redesign-reference/2026-10-23/screenshots/25-video-alternatives.jpg) | Vallejo selected; alternatives shown beneath matched paints. Alternatives add dense chips under each paint. Clarify recommendation quality and the difference between color and paint properties. |
| 26 | [Analyze video form](../design/redesign-reference/2026-10-23/screenshots/26-analyze-video-form.jpg) | Empty YouTube URL form; daily allowance shown; no analysis started. Keep the daily allowance visible and design queued, processing, failed and completed states. |
| 27 | [Public landing page](../design/redesign-reference/2026-10-23/screenshots/27-public-home.jpg) | Signed out; hero, primary and secondary calls to action, community count. Align the social/community promise with collection utility and the signed-in navigation. |
| 28 | [Landing page product showcase](../design/redesign-reference/2026-10-23/screenshots/28-home-product-showcase.jpg) | Scrolled to the existing marketing product-preview carousel; embedded screenshot is promotional content, not live app state. The embedded marketing screenshots show older navigation. Refresh them after the redesigned app is stable. |
| 29 | [Landing page community and conversion](../design/redesign-reference/2026-10-23/screenshots/29-home-community.jpg) | Community statistics and closing sign-up call to action. The local page shows 5 active painters while the closing copy says thousands. Reconcile claims with the displayed environment/data. |
| 30 | [Sign-in screen](../design/redesign-reference/2026-10-23/screenshots/30-sign-in.jpg) | Blank login form with remember-me and recovery links. The wordmark differs from the app header; inputs rely visually on placeholders. Include persistent labels and error/recovery designs. |
| 31 | [Registration screen](../design/redesign-reference/2026-10-23/screenshots/31-sign-up.jpg) | Blank registration form; no credentials entered and no account created. Align brand presentation and field patterns with sign-in; include validation, confirmation and first-run onboarding states. |
