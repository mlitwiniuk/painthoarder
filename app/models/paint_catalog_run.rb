class PaintCatalogRun < ApplicationRecord
  has_many :entries, class_name: "PaintCatalogEntry", dependent: :destroy
  validates :source, inclusion: {in: %w[monument army_painter]}
  validates :status, inclusion: {in: %w[queued running ready failed]}
  validates :automation_status, inclusion: {in: %w[pending completed blocked failed]}

  def self.start!(source, auto_apply: true)
    create!(source: source, auto_apply: auto_apply)
  end

  def large_drop?(count = entries.count)
    history = self.class.where(source: source, status: "ready").where("id < ?", id).order(id: :desc)
    # A blocked or partially failed refresh must not normalize a truncated feed
    # on the next day's run. Pre-automation previews bootstrap the first sync.
    previous = history.find_by(auto_apply: true, automation_status: "completed") || history.find_by(auto_apply: false)
    previous && count < previous.entries.count * 0.8
  end

  def reviewable?
    status == "ready" && finished_at > 14.days.ago &&
      !self.class.where(source: source, status: "ready").where("id > ?", id).exists?
  end

  def source_name
    PaintCatalog::Sources.fetch(source).fetch(:label)
  end
end
