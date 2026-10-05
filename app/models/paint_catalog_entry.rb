class PaintCatalogEntry < ApplicationRecord
  belongs_to :paint_catalog_run
  belongs_to :paint, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  validates :external_id, presence: true
  validates :action, inclusion: {in: %w[add link update unchanged ambiguous]}
  validates :status, inclusion: {in: %w[pending applied rejected]}
  validates :application_method, inclusion: {in: %w[automatic manual]}, allow_nil: true

  def self.paint_baseline(paint)
    paint.attributes.slice("name", "code", "product_line_id", "red", "green", "blue", "updated_at").as_json
  end
end
