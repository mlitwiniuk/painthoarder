# Ranks paints by perceptual similarity to a source paint.
#
# Two strategies:
#   :color - CIEDE2000 ΔE in CIELAB space ("closest match")
#   :hue   - hue-family proximity ("same hue family"), a deliberately
#            different lens that groups paints by colour identity rather
#            than exact match.
#
# The ordered, capped, threshold-filtered result list is cached: it only
# changes when the catalogue changes, so recomputing it per request (and
# per "load more" page) is wasteful. Pagination just slices the cached list.
class PaintSimilarityQuery
  MAX_RESULTS = 60
  COLOR_THRESHOLD = 25.0       # max ΔE2000 to count as "similar"
  HUE_THRESHOLD = 50.0         # max hue-family score to count as "similar"
  BOOST_TOLERANCE = 1.5        # ΔE band within which a related product line wins
  ACHROMATIC_SATURATION = 0.12 # below this, hue is meaningless
  LAB_BOX_HALF_WIDTH = 50.0    # pre-filter window per LAB axis (color strategy)
  CACHE_TTL = 1.hour

  STRATEGIES = %w[color hue].freeze
  DEFAULT_STRATEGY = "color"

  def initialize(source_paint, strategy: DEFAULT_STRATEGY, brand_ids: nil)
    @source = source_paint
    @strategy = STRATEGIES.include?(strategy.to_s) ? strategy.to_s : DEFAULT_STRATEGY
    @brand_ids = normalize_brand_ids(brand_ids)
  end

  attr_reader :strategy

  # Ordered [paint_id, score] pairs, capped at MAX_RESULTS and filtered to
  # the similarity threshold. Cached per source/strategy/brand filter.
  def ranked
    @ranked ||= Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { compute_ranked }
  end

  def total_count
    ranked.size
  end

  # Returns [{ paint:, score: }, ...] for the requested page, in ranked order.
  def page(page_num, per_page)
    page_num = [page_num.to_i, 1].max
    per_page = per_page.to_i.clamp(1, MAX_RESULTS)
    slice = ranked[(page_num - 1) * per_page, per_page] || []
    return [] if slice.empty?

    scores = slice.to_h
    paints = Paint.where(id: scores.keys).includes(product_line: :brand).index_by(&:id)
    slice.filter_map do |paint_id, score|
      paint = paints[paint_id]
      {paint: paint, score: score} if paint
    end
  end

  def more_after?(page_num, per_page)
    page_num.to_i * per_page.to_i < ranked.size
  end

  private

  def normalize_brand_ids(ids)
    return nil if ids.blank?

    Array(ids).map(&:to_s).reject(&:blank?).uniq.sort.presence
  end

  def cache_key
    [
      "paint_similarity", "v1", @strategy, @source.id,
      @brand_ids ? @brand_ids.join("-") : "all"
    ].join("/")
  end

  def compute_ranked
    family = @source.product_line.similar_product_line_ids.to_set
    threshold = (@strategy == "color") ? COLOR_THRESHOLD : HUE_THRESHOLD

    scored = candidate_rows.filter_map do |id, red, green, blue, lab_l, lab_a, lab_b, product_line_id|
      next if id == @source.id

      score = score_for(red, green, blue, [lab_l, lab_a, lab_b])
      next if score > threshold

      [id, score, family.include?(product_line_id)]
    end

    # Primary order is the perceptual score. Within a just-noticeable band,
    # prefer paints from a related product line - a bounded tiebreaker rather
    # than the old uncapped 0.7x multiplier that could promote poor matches.
    scored.sort_by! do |_id, score, in_family|
      [(score / BOOST_TOLERANCE).floor, in_family ? 0 : 1, score]
    end
    scored.first(MAX_RESULTS).map { |id, score, _| [id, score.round(2)] }
  end

  def candidate_rows
    rows = pluck_candidates(bounded_scope)
    # The LAB box can be sparse for gamut-edge colours; fall back to a full
    # scan so we never under-fill a page that real matches could satisfy.
    rows = pluck_candidates(base_scope) if @strategy == "color" && rows.size < MAX_RESULTS
    rows
  end

  def pluck_candidates(scope)
    scope.pluck(:id, :red, :green, :blue, :lab_l, :lab_a, :lab_b, :product_line_id)
  end

  def base_scope
    return Paint.all if @brand_ids.blank?

    Paint.joins(product_line: :brand).where(product_lines: {brand_id: @brand_ids})
  end

  def bounded_scope
    return base_scope unless @strategy == "color"

    l, a, b = @source.lab
    return base_scope if l.nil?

    half = LAB_BOX_HALF_WIDTH
    base_scope.where(
      lab_l: (l - half)..(l + half),
      lab_a: (a - half)..(a + half),
      lab_b: (b - half)..(b + half)
    )
  end

  def score_for(red, green, blue, lab)
    if @strategy == "color"
      ColorMath.ciede2000(@source.lab, lab)
    else
      hue_score(red, green, blue)
    end
  end

  def hue_score(red, green, blue)
    source_hue, source_saturation, source_value = source_hsv
    hue, saturation, value = ColorMath.rgb_to_hsv(red, green, blue)

    if source_saturation < ACHROMATIC_SATURATION
      # Achromatic source has no hue family; rank other neutrals by lightness.
      return Float::INFINITY if saturation >= ACHROMATIC_SATURATION

      return (source_value - value).abs * 100
    end

    return Float::INFINITY if saturation < ACHROMATIC_SATURATION

    ColorMath.hue_distance(source_hue, hue) + ((source_value - value).abs * 15)
  end

  def source_hsv
    @source_hsv ||= ColorMath.rgb_to_hsv(@source.red, @source.green, @source.blue)
  end
end
