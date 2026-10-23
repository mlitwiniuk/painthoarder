require "test_helper"

class DesignHelperTest < ActionView::TestCase
  test "status_tag renders word, icon and status class" do
    html = status_tag("wishlist")

    assert_includes html, "tag-wanted"
    assert_includes html, "Wanted"
    assert_includes html, "<svg"
  end

  test "status_tag shows pot count only when more than one" do
    assert_includes status_tag("owned", count: 2), "Owned × 2"
    assert_not_includes status_tag("owned", count: 1), "×"
  end

  test "status_tag is blank for unknown status unless add is requested" do
    assert_equal "", status_tag(nil)
    assert_includes status_tag(nil, add: true), "tag-add"
  end

  test "match_quality bands follow delta E thresholds" do
    assert_equal "Near-identical", match_quality(0.8)[:label]
    assert_equal 3, match_quality(2.4)[:level]
    assert_equal "Close", match_quality(4.3)[:label]
    assert_equal 1, match_quality(6.9)[:level]
    assert_nil match_quality(nil)
  end

  test "match_meter fills segments up to the level" do
    html = match_meter(3)

    assert_equal 3, html.scan('class="on"').size
    assert_equal 4, html.scan("<span").size - 1
  end

  test "user_initial upcases the first username letter" do
    assert_equal "M", user_initial(User.new(username: "maciej"))
  end
end
