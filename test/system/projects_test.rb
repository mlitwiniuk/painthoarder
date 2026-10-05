require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  setup do
    @user = create(:confirmed_user)
    @project = create(:project, :private, user: @user)
    login_as(@user, scope: :user)
  end

  test "visiting the index" do
    visit projects_url
    assert_selector "h1", text: "Projects"
    assert_link @project.title
  end

  test "creating a project" do
    visit projects_url
    find("a[href='#{new_project_path}']").click
    fill_in "project_title", with: "New miniature project"
    fill_in "project_description", with: "Painting a new army"
    select "🔒 Private - Only you can view", from: "project_visibility"
    click_on "Create Project"

    assert_selector "h1", text: "New miniature project"
    assert_text "Painting a new army"
    assert @user.projects.find_by!(title: "New miniature project").visibility_private?
  end

  test "updating a project" do
    visit project_url(@project)
    find(".navbar-end .dropdown > label").click
    click_on "Edit Project"
    fill_in "project_title", with: "Updated miniature project"
    click_on "Update Project"

    assert_selector "h1", text: "Updated miniature project"
    assert_equal "Updated miniature project", @project.reload.title
  end

  test "destroying a project" do
    visit project_url(@project)
    find(".navbar-end .dropdown > label").click
    accept_confirm("Are you sure?") { click_on "Delete Project" }

    assert_selector "h1", text: "Projects"
    assert_no_text @project.title
    assert_not Project.exists?(@project.id)
  end
end
