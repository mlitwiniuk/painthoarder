require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  test "catalog paginates 24 records and preserves filters in links" do
    line = create(:product_line)
    # Cross the production page size (24) to exercise the real pagination boundary.
    create_list(:paint, 25, product_line: line) # rubocop:disable FactoryBot/ExcessiveCreateList
    get paints_path, params: {q: {product_line_id_eq: line.id}}
    assert_response :success
    assert_select "nav.pagy.series-nav a[aria-current=page]", text: "1"
    assert_select "nav.pagy a[href*='page=2']" do |links|
      assert links.all? { |link| link["href"].include?("product_line_id_eq") }
    end
    assert_select ".pagy.info", text: /1-24 of 25/

    get paints_path, params: {q: {product_line_id_eq: line.id}, page: 2}
    assert_response :success
    assert_select ".pagy.info", text: /25-25 of 25/
  end

  test "out of range catalog pages redirect to the last page" do
    get paints_path, params: {page: 999, q: {name_cont: "No such paint"}}
    assert_response :moved_permanently
    assert_includes response.location, "page=1"
    follow_redirect!
    assert_response :success
  end
end
