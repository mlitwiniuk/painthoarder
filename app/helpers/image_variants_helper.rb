module ImageVariantsHelper
  VARIANT_PRESETS = {
    thumb:  { resize_to_fill: [300, 300], format: :webp, saver: { quality: 80, strip: true } },
    card:   { resize_to_fill: [600, 400], format: :webp, saver: { quality: 82, strip: true } },
    medium: { resize_to_limit: [800, 800], format: :webp, saver: { quality: 85, strip: true } },
    large:  { resize_to_limit: [1200, 1200], format: :webp, saver: { quality: 85, strip: true } },
    cover:  { resize_to_limit: [1600, 1200], format: :webp, saver: { quality: 85, strip: true } },
    og:     { resize_to_fill: [1200, 630], format: :jpeg, saver: { quality: 85, strip: true } }
  }.freeze

  def optimized_variant(image, preset)
    options = VARIANT_PRESETS.fetch(preset)
    image.variant(**options)
  end
end
