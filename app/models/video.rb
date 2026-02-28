class Video < ApplicationRecord
  ## FRIENDLY ID
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :history]

  ## ASSOCIATIONS
  belongs_to :user
  has_many :video_paints, dependent: :destroy

  ## ENUMS
  enum :status, {pending: 0, processing: 1, completed: 2, failed: 3}

  ## VALIDATIONS
  validates :youtube_video_id, presence: true, uniqueness: true

  ## SCOPES
  scope :completed, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  def slug_candidates
    [[:author_name, :title]]
  end

  def should_generate_new_friendly_id?
    slug.blank? || title_changed?
  end

  # Extract YouTube video ID from various URL formats
  def self.extract_video_id(url)
    return nil if url.blank?

    patterns = [
      /(?:youtube\.com\/watch\?v=|youtube\.com\/watch\?.+&v=)([^&\s]+)/,
      /youtu\.be\/([^\?\s]+)/,
      /youtube\.com\/embed\/([^\?\s]+)/,
      /youtube\.com\/shorts\/([^\?\s]+)/,
      /youtube\.com\/v\/([^\?\s]+)/
    ]

    patterns.each do |pattern|
      match = url.match(pattern)
      return match[1] if match
    end

    nil
  end

  def youtube_url
    "https://www.youtube.com/watch?v=#{youtube_video_id}"
  end

  def embed_url
    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  def default_thumbnail_url
    "https://img.youtube.com/vi/#{youtube_video_id}/maxresdefault.jpg"
  end

  def matched_paints_count
    video_paints.where.not(paint_id: nil).count
  end

  def unmatched_paints_count
    video_paints.where(paint_id: nil).count
  end
end
