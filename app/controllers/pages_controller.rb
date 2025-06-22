class PagesController < ApplicationController
  before_action :set_page, only: %i[show edit update destroy]
  before_action :authenticate_user!, except: %i[welcome show]
  before_action :authorize_admin!, only: %i[index new create edit update destroy]

  def index
    @pages = Page.all
    respond_with(@pages)
  end

  def welcome
    @last_users = User.order(created_at: :desc).limit(5)
    @user_count = User.count
    @paint_count = Paint.count
    @project_count = Project.count

    # Redirect to dashboard if already logged in
    redirect_to user_root_path if user_signed_in?
  end

  def show
    respond_with(@page)
  rescue ActiveRecord::RecordNotFound
    render static_page
  end

  def new
    @page = Page.new
    respond_with(@page)
  end

  def edit
  end

  def create
    @page = Page.new(page_params)
    @page.save
    respond_with(@page)
  end

  def update
    @page.update(page_params)
    respond_with(@page)
  end

  def destroy
    @page.destroy!
    respond_with(@page)
  end

  private

  def set_page
    @page = Page
    @page = if user_signed_in? && current_user.admin?
      @page.friendly.find(params[:id])
    else
      @page.issued.friendly.find(params[:id])
    end
  end

  def page_params
    params.require(:page).permit(:title, :content, :published, :prefrences, :status)
  end

  def static_page
    # only allow certain pages to be rendered
    %w[about themes welcome icons].include?(params[:id]) ? params[:id] : "welcome"
  end
end
