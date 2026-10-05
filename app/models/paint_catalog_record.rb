# The producer's identity is separate from our permanent paint ID and display code.
class PaintCatalogRecord < ApplicationRecord
  belongs_to :paint
  validates :source, :external_id, :sku, :source_url, presence: true
end
