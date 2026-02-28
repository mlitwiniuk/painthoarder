require "test_helper"

class ProductLineSimilarityTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:product_line)
    should belong_to(:similar_product_line).class_name("ProductLine")
  end

  context "validations" do
    should "require unique product_line + similar_product_line pair" do
      similarity = create(:product_line_similarity)
      duplicate = build(:product_line_similarity,
        product_line: similarity.product_line,
        similar_product_line: similarity.similar_product_line)
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:similar_product_line_id], "has already been taken"
    end

    should "prevent self-referential similarity" do
      pl = create(:product_line)
      similarity = build(:product_line_similarity, product_line: pl, similar_product_line: pl)
      assert_not similarity.valid?
      assert_includes similarity.errors[:similar_product_line_id], "can't be the same as the product line"
    end
  end

  test "can create a valid product line similarity" do
    pl_a = create(:product_line)
    pl_b = create(:product_line)
    similarity = build(:product_line_similarity, product_line: pl_a, similar_product_line: pl_b)
    assert similarity.valid?
    assert_difference("ProductLineSimilarity.count") do
      similarity.save!
    end
  end

  test "product_line has similar_product_lines through association" do
    pl_a = create(:product_line)
    pl_b = create(:product_line)
    pl_c = create(:product_line)

    create(:product_line_similarity, product_line: pl_a, similar_product_line: pl_b)
    create(:product_line_similarity, product_line: pl_a, similar_product_line: pl_c)

    assert_equal 2, pl_a.similar_product_lines.count
    assert_includes pl_a.similar_product_lines, pl_b
    assert_includes pl_a.similar_product_lines, pl_c
  end
end
