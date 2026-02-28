# Models Reference

## User
- Devise: database_authenticatable, registerable, recoverable, rememberable, validatable, lockable, confirmable
- `has_many :user_paints` / `has_many :paints, through: :user_paints` / `has_many :projects`
- Store accessor: `similar_paint_brand_ids` (in preferences JSON)
- Validates: username (presence, max 20, unique, UsernameValidator)
- Login: `find_for_database_authentication` supports email or username
- After confirm: sends welcome email

## Brand
- `has_one_attached :logo`
- `has_many :product_lines, dependent: :destroy` / `has_many :paints, through: :product_lines`
- Validates: name (presence, uniqueness)

## ProductLine
- `belongs_to :brand` / `has_many :paints, dependent: :destroy`
- Validates: name (presence)

## Paint
- `includes SqliteSearch` — FTS5 on name, code, brand_name, product_line_name, name_code_normalized
- `has_one_attached :image`
- `belongs_to :product_line` / `has_one :brand, through: :product_line` / `has_many :user_paints`
- Validates: name, code (presence), red/green/blue (integer 0-255)
- Before save: calculates hex_color from RGB
- Methods: `hsv_values`, `color_category`, `brand_name`, `product_line_name`, `name_code_normalized`
- Stats: `owned_count`, `wishlist_count`, `avoid_count`, `total_users_count`, `collection_stats`
- Scope: `full_search(query)` — FTS5 prefix search

## UserPaint
- `belongs_to :paint` / `belongs_to :user`
- Enum: `status` — owned(0), wishlist(1), avoid(2)
- Virtual attr: `virtual` — for non-persisted instances (paint not in collection)
- Methods: `virtual?`, `in_collection?`, `display_status`, `can_add_to_collection?`
- Status override: returns "not_in_collection" when virtual

## Project
- `belongs_to :user` / `has_many :project_updates, dependent: :destroy` / `has_one_attached :cover_photo`
- Enum: `visibility` — private(0), restricted(1), public(2)
- Validates: title (presence), visibility (presence), cover_photo (content_type, size < 5MB)
- Before validation: generates `secret_token` (SecureRandom)
- Scopes: `visibility_restricted_or_public`, `viewable_by(user)`
- Accepts nested: `project_updates`

## ProjectUpdate
- `acts_as_list scope: :project`
- `belongs_to :project` / `has_many_attached :photos` / `has_many :paint_usages, dependent: :destroy`
- `has_many :user_paints, through: :paint_usages`
- `belongs_to :primary_photo, class_name: 'ActiveStorage::Attachment', optional: true`
- Default scope: `order(position: :asc)`

## PaintUsage
- `belongs_to :project_update` / `belongs_to :user_paint`
- Simple join model, cascade deletes via FK

## Page
- FriendlyId slugged on title
- Enum: `status` — draft(0), issued(1), archived(99)
- `has_rich_text :content`
- Validates: title (presence, uniqueness, 5-150), content (presence)
