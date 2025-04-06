class PagesController < ApplicationController
  before_action :set_page, only: %i[edit update destroy]
  before_action :authenticate_user!, except: %i[welcome show]

  def index
    @pages = Page.all
    respond_with(@pages)
  end

  def welcome
    @user_count = User.count
    @paint_count = Paint.count

    # Redirect to dashboard if already logged in
    redirect_to user_root_path if user_signed_in?
  end

  def show
    @page = Page.find(params[:id])
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
    @page = Page.find(params[:id])
  end

  def page_params
    params.require(:page).permit(:title, :content, :published, :prefrences, :status)
  end

  def static_page
    # only allow certain pages to be rendered
    %w[about themes welcome icons].include?(params[:id]) ? params[:id] : "welcome"
  end
end
