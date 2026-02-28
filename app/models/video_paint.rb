class VideoPaint < ApplicationRecord
  ## ASSOCIATIONS
  belongs_to :video
  belongs_to :paint, optional: true

  ## VALIDATIONS
  validates :paint_name, presence: true

  ## SCOPES
  scope :matched, -> { where.not(paint_id: nil) }
  scope :unmatched, -> { where(paint_id: nil) }

  def matched?
    paint_id.present?
  end
end
