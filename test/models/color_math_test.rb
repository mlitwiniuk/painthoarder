require "test_helper"

class ColorMathTest < ActiveSupport::TestCase
  test "rgb_to_lab converts white to L=100, neutral a/b" do
    l, a, b = ColorMath.rgb_to_lab(255, 255, 255)
    assert_in_delta 100.0, l, 0.01
    assert_in_delta 0.0, a, 0.05
    assert_in_delta 0.0, b, 0.05
  end

  test "rgb_to_lab converts black to all zeros" do
    assert_equal [0.0, 0.0, 0.0], ColorMath.rgb_to_lab(0, 0, 0)
  end

  test "rgb_to_lab converts mid grey to neutral chroma" do
    l, a, b = ColorMath.rgb_to_lab(128, 128, 128)
    assert_in_delta 53.6, l, 0.5
    assert_in_delta 0.0, a, 0.05
    assert_in_delta 0.0, b, 0.05
  end

  test "rgb_to_lab puts pure red in the positive-a, positive-b quadrant" do
    _l, a, b = ColorMath.rgb_to_lab(255, 0, 0)
    assert a > 60, "expected strongly positive a* for red"
    assert b > 30, "expected positive b* for red"
  end

  # Reference values from Sharma, Wu & Dalal (2005) CIEDE2000 test data.
  test "ciede2000 matches published reference vectors" do
    assert_in_delta 2.0425,
      ColorMath.ciede2000([50.0, 2.6772, -79.7751], [50.0, 0.0, -82.7485]), 0.001
    assert_in_delta 2.8615,
      ColorMath.ciede2000([50.0, 3.1571, -77.2803], [50.0, 0.0, -82.7485]), 0.001
    assert_in_delta 1.2644,
      ColorMath.ciede2000([60.2574, -34.0099, 36.2677], [60.4626, -34.1751, 39.4387]), 0.001
    assert_in_delta 1.8645,
      ColorMath.ciede2000([35.0831, -44.1164, 3.7933], [35.0232, -40.0716, 1.5901]), 0.001
  end

  test "ciede2000 of identical colours is zero" do
    assert_equal 0.0, ColorMath.ciede2000([42.0, 10.0, -5.0], [42.0, 10.0, -5.0])
  end

  test "rgb_to_hsv returns hue, saturation, value" do
    h, s, v = ColorMath.rgb_to_hsv(255, 0, 0)
    assert_in_delta 0.0, h, 0.01
    assert_in_delta 1.0, s, 0.01
    assert_in_delta 1.0, v, 0.01

    h, s, v = ColorMath.rgb_to_hsv(0, 255, 0)
    assert_in_delta 120.0, h, 0.01

    _h, s, v = ColorMath.rgb_to_hsv(128, 128, 128)
    assert_in_delta 0.0, s, 0.01
    assert_in_delta 0.502, v, 0.01
  end

  test "hue_distance is circular and shortest-path" do
    assert_equal 0, ColorMath.hue_distance(10, 10)
    assert_equal 20, ColorMath.hue_distance(350, 10)
    assert_equal 180, ColorMath.hue_distance(0, 180)
    assert_equal 90, ColorMath.hue_distance(45, 315)
  end
end
