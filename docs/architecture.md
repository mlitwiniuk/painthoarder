# PaintHoarder Architecture

Rails 8.1 / Ruby 3.4.7 / SQLite / Hotwire / DaisyUI

## Domain

Miniature paint collection manager. Users track owned/wishlist/avoid paints, create projects with photo updates showing paint usage, share projects publicly.

## Data Model

```
User -< UserPaint >- Paint >- ProductLine >- Brand
User -< Project -< ProjectUpdate -< PaintUsage >- UserPaint
Page (CMS, standalone)
```

### Key Tables

| Table | Key Columns | Notes |
|---|---|---|
| users | email, username, is_admin, preferences (JSON) | Devise auth (confirmable, lockable) |
| brands | name (unique) | has_one_attached :logo |
| product_lines | brand_id, name | cascade delete from brand |
| paints | product_line_id, name, code, red, green, blue, hex_color | FTS5 search, has_one_attached :image |
| user_paints | user_id, paint_id, status (enum: owned/wishlist/avoid), notes, purchase_date, purchase_price | |
| projects | user_id, title, visibility (enum: private/restricted/public), secret_token | has_one_attached :cover_photo |
| project_updates | project_id, title, description, position | acts_as_list, has_many_attached :photos |
| paint_usages | project_update_id, user_paint_id | join table |
| pages | title, slug (friendly_id), status, content (Action Text) | CMS |
| fts_paints | virtual FTS5 table | full-text search on name, code, brand, product_line |

### Enums

- `UserPaint.status`: owned(0), wishlist(1), avoid(2)
- `Project.visibility`: private(0), restricted(1), public(2)
- `Page.status`: draft(0), issued(1), archived(99)

## Controllers

| Controller | Key Actions | Notes |
|---|---|---|
| PaintsController | index, show, search, similar | Catalog browsing, ransack filtering, FTS search, RGB/HSL similarity |
| UserPaintsController | index, create, update, destroy, bulk_import, bulk_search, bulk_search_from_photo, color_wheel | Collection management, LLM photo analysis |
| ProjectsController | index, public_index, restricted, show, CRUD | Visibility scoping, secret_token sharing |
| ProjectUpdatesController | new, create, edit, update, destroy | Nested under projects, turbo frame aware |
| DashboardController | index | Stats: counts, recent additions, color distribution |
| PagesController | welcome, show, CRUD | Admin CMS + public static pages |
| Api::* | Brands, ProductLines, Paints (JSON) | Cascading select dropdowns |

## Services

| Service | Purpose |
|---|---|
| PaintPhotoAnalyzer | LLM vision (RubyLLM + claude-haiku-4-5) identifies paints from photos. Uses RubyLLM::Tool for structured output. |
| MarkdownColorParser | Parses markdown tables with paint/color data for bulk import |

## Concerns & Modules

| Name | Location | Purpose |
|---|---|---|
| Filterable | controllers/concerns | Status, search, color filtering for paints/user_paints |
| SqliteSearch | models/concerns | FTS5 full-text search via SQLite virtual tables |
| ColorCategorization | lib (module) | RGB→category mapping (12+ categories), color filtering SQL |

## Frontend Stack

- **CSS**: TailwindCSS 4 + DaisyUI 5 + Propshaft
- **JS**: esbuild (entry: `app/assets/javascripts/application.js`)
- **Stimulus controllers**: `app/assets/javascripts/controllers/` (29 controllers)
- **Turbo**: Heavy use of turbo_stream responses for index/show/search/create/update
- **PWA**: Workbox service worker

### Key Stimulus Controllers

| Controller | Purpose |
|---|---|
| search_controller | Live paint search |
| cascading_select_controller | Brand→ProductLine→Paint dropdowns |
| color_wheel_controller | D3.js color wheel visualization |
| color_picker_controller | RGB color filter |
| add_to_collection_controller | Quick add paint to collection |
| photo_analyze_controller | LLM photo upload flow |
| modal_controller | DaisyUI modal management |
| tinymce_controller | Rich text editor for pages |
| theme_controller | Theme switching |

## Auth & Authorization

- Devise (database_authenticatable, confirmable, lockable)
- Login via username or email
- Admin check: `current_user.admin?` (boolean column)
- No Pundit/CanCanCan — manual `authorize_admin!` and `ensure_owner`

## External Integrations

- **RubyLLM**: Claude API for paint photo analysis (credentials: `llm.anthropic_api_key`)
- **AWS S3**: Active Storage in production
- **Mailgun**: Email delivery
- **AppSignal**: Monitoring
