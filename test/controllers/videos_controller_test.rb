require "test_helper"

class VideosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :confirmed)
    @other_user = create(:user, :confirmed)
    @completed_video = create(:video, :completed, user: @user, title: "My Tutorial")
    @other_video = create(:video, :completed, user: @other_user, title: "Other Tutorial")
    sign_in @user
  end

  # Public Index
  test "public_index is accessible without auth" do
    sign_out @user
    get public_videos_url
    assert_response :success
  end

  test "public_index shows only completed videos" do
    pending = create(:video, user: @user, status: :pending, title: "Pending Video")

    get public_videos_url
    assert_response :success
    assert_includes response.body, @completed_video.title
    assert_includes response.body, @other_video.title
    assert_not_includes response.body, pending.title
  end

  # Index
  test "index requires authentication" do
    sign_out @user
    get videos_url
    assert_redirected_to new_user_session_path
  end

  test "index shows only current user videos" do
    get videos_url
    assert_response :success
    assert_includes response.body, @completed_video.title
    assert_not_includes response.body, @other_video.title
  end

  # Show
  test "show is accessible without auth for completed video" do
    sign_out @user
    get video_url(@completed_video)
    assert_response :success
    assert_includes response.body, @completed_video.title
  end

  test "show redirects for non-completed video when not owner" do
    pending_video = create(:video, user: @other_user, status: :pending)
    get video_url(pending_video)
    assert_redirected_to public_videos_path
  end

  test "show allows owner to see pending video" do
    pending_video = create(:video, user: @user, status: :pending)
    get video_url(pending_video)
    assert_response :success
  end

  test "show allows owner to see processing video" do
    processing_video = create(:video, :processing, user: @user)
    get video_url(processing_video)
    assert_response :success
  end

  test "show allows owner to see failed video" do
    failed_video = create(:video, :failed, user: @user)
    get video_url(failed_video)
    assert_response :success
  end

  # New
  test "new requires authentication" do
    sign_out @user
    get new_video_url
    assert_redirected_to new_user_session_path
  end

  test "new renders form" do
    get new_video_url
    assert_response :success
  end

  # Create
  test "create requires authentication" do
    sign_out @user
    post videos_url, params: {url: "https://www.youtube.com/watch?v=test123"}
    assert_redirected_to new_user_session_path
  end

  test "create with valid YouTube URL" do
    stub_oembed_request("newvideo1")

    assert_difference("Video.count") do
      post videos_url, params: {url: "https://www.youtube.com/watch?v=newvideo1"}
    end

    video = Video.last
    assert_equal "newvideo1", video.youtube_video_id
    assert_equal @user, video.user
    assert video.pending?
    assert_redirected_to video_url(video)
  end

  test "create with invalid URL renders new" do
    assert_no_difference("Video.count") do
      post videos_url, params: {url: "not-a-youtube-url"}
    end
    assert_response :unprocessable_entity
  end

  test "create redirects to existing video for duplicate URL" do
    existing = create(:video, youtube_video_id: "existing123")

    assert_no_difference("Video.count") do
      post videos_url, params: {url: "https://www.youtube.com/watch?v=existing123"}
    end

    assert_redirected_to video_url(existing)
  end

  test "create enqueues VideoAnalysisJob" do
    stub_oembed_request("jobtest1")

    assert_enqueued_with(job: VideoAnalysisJob) do
      post videos_url, params: {url: "https://www.youtube.com/watch?v=jobtest1"}
    end
  end

  # Destroy
  test "destroy requires authentication" do
    sign_out @user
    delete video_url(@completed_video)
    assert_redirected_to new_user_session_path
  end

  test "destroy works for owner" do
    assert_difference("Video.count", -1) do
      delete video_url(@completed_video)
    end
    assert_redirected_to videos_url
  end

  test "destroy forbidden for non-owner" do
    assert_no_difference("Video.count") do
      delete video_url(@other_video)
    end
    assert_redirected_to videos_path
  end

  test "destroy returns 404 for non-existent video" do
    delete video_url(id: 999999)
    assert_response :not_found
  end

  private

  def stub_oembed_request(video_id)
    oembed_response = {
      "title" => "Test Video",
      "author_name" => "Test Channel"
    }.to_json

    stub_request = Net::HTTPSuccess.new("1.1", "200", "OK")
    stub_request.stubs(:body).returns(oembed_response)
    Net::HTTP.stubs(:get_response).returns(stub_request)
  end
end
