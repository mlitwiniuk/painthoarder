# == Schema Information
#
# Table name: user_paints
#
#  id             :integer          not null, primary key
#  notes          :text
#  purchase_date  :date
#  purchase_price :decimal(, )
#  status         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  paint_id       :integer          not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_user_paints_on_paint_id  (paint_id)
#  index_user_paints_on_user_id   (user_id)
#
# Foreign Keys
#
#  paint_id  (paint_id => paints.id)
#  user_id   (user_id => users.id)
#
require "test_helper"

class UserPaintTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:status)
  end

  context "associations" do
    should belong_to(:paint)
    should belong_to(:user)
  end

  test "can create a user_paint with valid attributes" do
    user_paint = build(:user_paint)
    assert user_paint.valid?
    assert_difference('UserPaint.count') do
      user_paint.save
    end
  end

  test "has valid status enum values" do
    user_paint = create(:user_paint)

    # Test owned status
    user_paint.owned!
    assert user_paint.owned?

    # Test wishlist status
    user_paint.wishlist!
    assert user_paint.wishlist?

    # Test avoid status
    user_paint.avoid!
    assert user_paint.avoid?
  end

  test "purchase details are optional for wishlist and avoid" do
    wishlist_paint = build(:user_paint, :wishlist)
    assert wishlist_paint.valid?

    avoid_paint = build(:user_paint, :avoid)
    assert avoid_paint.valid?
  end
end
