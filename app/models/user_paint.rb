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
class UserPaint < ApplicationRecord

  ## ATTRIBUTES
  enum :status, { owned: 0, wishlist: 1, avoid: 2 }
  
  # Virtual attribute for non-persisted similar paint recommendations
  attr_accessor :virtual
  
  ## ASSOCIATIONS
  belongs_to :paint
  belongs_to :user

  ## VALIDATIONS
  validates :status, presence: true, unless: :virtual?
  
  # Check if this is a virtual (non-persisted) UserPaint object
  def virtual?
    virtual == true
  end
  
  # Default status for virtual paints
  def status
    return 'similar' if virtual?
    super
  end
end
