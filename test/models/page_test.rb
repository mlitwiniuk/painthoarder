require "test_helper"

class PageTest < ActiveSupport::TestCase
  context 'validations' do
    should validate_presence_of(:title)
    should validate_uniqueness_of(:title)
    should validate_length_of(:title).is_at_least(5).is_at_most(150)
    should validate_presence_of(:content)
  end

  context 'enum definitions' do
    should define_enum_for(:status).with_values(draft: 0, issued: 1, archived: 99)
  end

  test "has draft status by default" do
    page = build(:page)
    assert page.draft?
  end

  test "can transition between statuses" do
    page = create(:page)
    assert page.draft?

    page.issued!
    assert page.issued?
    assert_not page.draft?

    page.archived!
    assert page.archived?
    assert_not page.issued?
  end

  test "factory traits create pages with correct status" do
    draft_page = create(:page)
    issued_page = create(:page, :issued)
    archived_page = create(:page, :archived)

    assert draft_page.draft?
    assert issued_page.issued?
    assert archived_page.archived?
  end

  test "rejects titles that are too short" do
    page = build(:page, title: "Test")
    assert_not page.valid?
    assert_includes page.errors[:title], "is too short (minimum is 5 characters)"
  end

  test "rejects titles that are too long" do
    page = build(:page, title: "a" * 151)
    assert_not page.valid?
    assert_includes page.errors[:title], "is too long (maximum is 150 characters)"
  end
end
