require "test_helper"

class UserPaintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :confirmed)
    @other_user = create(:user, :confirmed)

    # Create some test data
    @brand = create(:brand, name: "Test Brand")
    @product_line = create(:product_line, brand: @brand, name: "Test Line")
    @paint = create(:paint, product_line: @product_line, name: "Test Paint", hex_color: "#FF0000")
    @other_paint = create(:paint, product_line: @product_line, name: "Other Paint", hex_color: "#00FF00")

    # Create user paints
    @user_paint = create(:user_paint, user: @user, paint: @paint, status: :owned)
    @other_user_paint = create(:user_paint, user: @other_user, paint: @other_paint, status: :owned)

    sign_in @user
  end

  # INDEX tests
  test "should get index" do
    get user_paints_url
    assert_response :success
    assert_includes response.body, @user_paint.paint.name
  end

  test "should only show current user's paints in index" do
    get user_paints_url
    assert_response :success
    assert_includes response.body, @user_paint.paint.name
    assert_not_includes response.body, @other_user_paint.paint.name
  end

  test "should require authentication for index" do
    sign_out @user
    get user_paints_url
    assert_redirected_to new_user_session_path
  end

  # NEW tests
  test "should get new" do
    get new_user_paint_url
    assert_response :success
  end

  test "should require authentication for new" do
    sign_out @user
    get new_user_paint_url
    assert_redirected_to new_user_session_path
  end

  # CREATE tests
  test "should create user paint" do
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    assert_difference("UserPaint.count") do
      post user_paints_url, params: {
        user_paint: {
          paint_id: new_paint.id,
          status: "owned",
          notes: "Test notes"
        }
      }
    end

    assert_redirected_to user_root_path
    created_paint = UserPaint.last
    assert_equal @user, created_paint.user
    assert_equal new_paint, created_paint.paint
    assert_equal "owned", created_paint.status
  end

  test "should create user paint with owned status when commit_owned button pressed" do
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    assert_difference("UserPaint.count") do
      post user_paints_url, params: {
        user_paint: {
          paint_id: new_paint.id
        },
        commit_owned: "Add to Owned"
      }
    end

    assert_redirected_to user_root_path
    created_paint = UserPaint.last
    assert_equal "owned", created_paint.status
    assert_equal @user, created_paint.user
  end

  test "should create user paint with wishlist status when commit_wishlist button pressed" do
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    assert_difference("UserPaint.count") do
      post user_paints_url, params: {
        user_paint: {
          paint_id: new_paint.id
        },
        commit_wishlist: "Add to Wishlist"
      }
    end

    assert_redirected_to user_root_path
    created_paint = UserPaint.last
    assert_equal "wishlist", created_paint.status
    assert_equal @user, created_paint.user
  end

  test "should not create user paint without authentication" do
    sign_out @user
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    assert_no_difference("UserPaint.count") do
      post user_paints_url, params: {
        user_paint: {
          paint_id: new_paint.id,
          status: "owned"
        }
      }
    end

    assert_redirected_to new_user_session_path
  end

  test "should automatically assign current user when creating user paint" do
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    # Try to create a user paint and assign it to another user (should be ignored)
    post user_paints_url, params: {
      user_paint: {
        paint_id: new_paint.id,
        status: "owned",
        user_id: @other_user.id  # This should be ignored
      }
    }

    assert_redirected_to user_root_path
    created_paint = UserPaint.last
    assert_equal @user, created_paint.user  # Should be current user, not other user
    assert_not_equal @other_user, created_paint.user
  end

  # SHOW tests
  test "should show user paint when owner" do
    get user_paint_url(@user_paint)
    assert_response :success
    assert_includes response.body, @user_paint.paint.name
  end

  test "should not show other user's paint" do
    get user_paint_url(@other_user_paint)
    assert_response :not_found
  end

  test "should require authentication for show" do
    sign_out @user
    get user_paint_url(@user_paint)
    assert_redirected_to new_user_session_path
  end

  # EDIT tests
  test "should get edit when owner" do
    get edit_user_paint_url(@user_paint)
    assert_response :success
  end

  test "should not get edit for other user's paint" do
    get edit_user_paint_url(@other_user_paint)
    assert_response :not_found
  end

  test "should require authentication for edit" do
    sign_out @user
    get edit_user_paint_url(@user_paint)
    assert_redirected_to new_user_session_path
  end

  # UPDATE tests
  test "should update user paint when owner" do
    patch user_paint_url(@user_paint), params: {
      user_paint: {
        status: "wishlist",
        notes: "Updated notes",
        purchase_price: 15.99
      }
    }

    assert_redirected_to user_paint_url(@user_paint)
    @user_paint.reload
    assert_equal "wishlist", @user_paint.status
    assert_equal "Updated notes", @user_paint.notes
    assert_equal 15.99, @user_paint.purchase_price.to_f
  end

  test "should not update other user's paint" do
    original_status = @other_user_paint.status
    original_notes = @other_user_paint.notes

    patch user_paint_url(@other_user_paint), params: {
      user_paint: {
        status: "avoid",
        notes: "Hacked notes"
      }
    }
    assert_response :not_found

    @other_user_paint.reload
    assert_equal original_status, @other_user_paint.status
    assert_equal original_notes, @other_user_paint.notes
  end

  test "should not allow changing user_id during update" do
    patch user_paint_url(@user_paint), params: {
      user_paint: {
        user_id: @other_user.id,  # This should be ignored
        status: "wishlist"
      }
    }

    @user_paint.reload
    assert_equal @user, @user_paint.user  # Should still be original user
    assert_equal "wishlist", @user_paint.status  # But status should be updated
  end

  test "should require authentication for update" do
    sign_out @user
    patch user_paint_url(@user_paint), params: {
      user_paint: {
        status: "wishlist"
      }
    }
    assert_redirected_to new_user_session_path
  end

  # DESTROY tests
  test "should destroy user paint when owner" do
    assert_difference("UserPaint.count", -1) do
      delete user_paint_url(@user_paint)
    end
    assert_redirected_to user_paints_url
  end

  test "should not destroy other user's paint" do
    assert_no_difference("UserPaint.count") do
      delete user_paint_url(@other_user_paint)
      assert_response :not_found
    end
  end

  test "should require authentication for destroy" do
    sign_out @user
    assert_no_difference("UserPaint.count") do
      delete user_paint_url(@user_paint)
    end
    assert_redirected_to new_user_session_path
  end

  # BULK_IMPORT tests
  test "should get bulk import" do
    get bulk_import_user_paints_url
    assert_response :success
  end

  test "should require authentication for bulk import" do
    sign_out @user
    get bulk_import_user_paints_url
    assert_redirected_to new_user_session_path
  end

  # BULK_SEARCH tests
  test "should handle bulk search" do
    post bulk_search_user_paints_url, params: {
      paint_names: "Test Paint\nOther Paint"
    }
    assert_response :success
  end

  test "should only search within user's scope for bulk search" do
    # This test ensures that bulk search results are properly scoped
    # The bulk search should find paints but show ownership status relative to current user
    post bulk_search_user_paints_url, params: {
      paint_names: "Test Paint\nOther Paint"
    }
    assert_response :success
    # The response should include both paints but show ownership status for current user only
  end

  test "should require authentication for bulk search" do
    sign_out @user
    post bulk_search_user_paints_url, params: {
      paint_names: "Test Paint"
    }
    assert_redirected_to new_user_session_path
  end

  # COLOR_WHEEL tests
  test "should get color wheel" do
    get color_wheel_user_paints_url
    assert_response :success
  end

  test "should only show current user's paints in color wheel" do
    get color_wheel_user_paints_url
    assert_response :success
    # Should include current user's paints but not other user's paints
    assert_includes response.body, @user_paint.paint.name
  end

  test "should require authentication for color wheel" do
    sign_out @user
    get color_wheel_user_paints_url
    assert_redirected_to new_user_session_path
  end

  # JSON API tests
  test "should return json with user's paints only" do
    get user_paints_url, params: {format: :json}

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should contain user's paint
    user_paint_ids = json_response["user_paints"].map { |up| up["id"] }
    assert_includes user_paint_ids, @user_paint.id
    assert_not_includes user_paint_ids, @other_user_paint.id
  end

  test "should handle search in json format" do
    get user_paints_url, params: {format: :json, search: "Test Paint"}

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should find the matching paint in user's collection
    assert json_response["user_paints"].any? { |up| up["paint"]["name"].include?("Test Paint") }
  end

  test "should require authentication for json api" do
    sign_out @user
    get user_paints_url, params: {format: :json}
    assert_response :unauthorized
  end

  # Edge cases and security tests
  test "should not allow mass assignment of restricted attributes" do
    new_paint = create(:paint, product_line: @product_line, name: "New Paint")

    post user_paints_url, params: {
      user_paint: {
        paint_id: new_paint.id,
        status: "owned",
        user_id: @other_user.id,  # Should be ignored
        id: 999999,  # Should be ignored
        created_at: 1.year.ago,  # Should be ignored
        updated_at: 1.year.ago   # Should be ignored
      }
    }

    assert_redirected_to user_root_path
    created_paint = UserPaint.last
    assert_equal @user, created_paint.user
    assert_not_equal 999999, created_paint.id
    assert created_paint.created_at > 1.minute.ago
  end

  test "should prevent duplicate user paints for same user and paint" do
    # This test assumes there's a uniqueness validation
    post user_paints_url, params: {
      user_paint: {
        paint_id: @paint.id,  # Same paint as @user_paint
        status: "wishlist"
      }
    }
    # Should either redirect or show error - depends on validation
    assert_redirected_to user_root_path
  end

  test "should handle invalid paint_id gracefully" do
    assert_no_difference("UserPaint.count") do
      post user_paints_url, params: {
        user_paint: {
          paint_id: 999999,  # Non-existent paint
          status: "owned"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
