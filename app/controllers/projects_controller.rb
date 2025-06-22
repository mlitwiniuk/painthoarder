class ProjectsController < ApplicationController
  before_action :authenticate_user!, except: %i[public_index restricted show]
  before_action :set_project, only: %i[show edit update destroy]
  before_action :set_current_user_paints, only: %i[show ]

  # GET /projects/my (default index)
  def index
    @projects = current_user.projects.includes(:project_updates).order(updated_at: :desc)
  end

  # GET /projects/public
  def public_index
    @projects = Project.visibility_public.includes(:user).order(updated_at: :desc)
    render :index
  end

  # GET /p/:token
  def restricted
    @project = Project.visibility_restricted_or_public.find_by!(secret_token: params[:token])
    set_current_user_paints
    render :show
  end

  # GET /projects/1 or /projects/1.json
  def show
    # Preload current user's paints for optimization if user is signed in
    redirect_to restricted_project_path(@project.secret_token) unless @project.visibility_private?
  end

  # GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects or /projects.json
  def create
    @project = current_user.projects.build(project_params)

    respond_to do |format|
      if @project.save
        set_cover_photo!
        format.html { redirect_to @project, notice: "Project was successfully created." }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1 or /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        set_cover_photo!
        format.html { redirect_to @project, notice: "Project was successfully updated." }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1 or /projects/1.json
  def destroy
    @project.destroy!

    respond_to do |format|
      format.html { redirect_to projects_path, status: :see_other, notice: "Project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_cover_photo!
    return if params[:project][:selected_cover_photo_id].blank?

    attachment = ActiveStorage::Attachment.find_by(id: params[:project][:selected_cover_photo_id])
    return unless attachment

    # avoid duplicate attachment if already set
    if @project.cover_photo.attached?
      @project.cover_photo.purge_later unless @project.cover_photo.id == attachment.id
      already_attached = @project.cover_photo.attachments.exists?(id: attachment.id) if @project.cover_photo.attachments
    else
      already_attached = false
    end
    @project.cover_photo.attach(attachment.blob) unless already_attached
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_params
    params_hash = params.require(:project).permit(
      :title,
      :description,
      :visibility,
      :selected_cover_photo_id,
      project_updates_attributes: [
        :id,
        :title,
        :description,
        :position,
        :primary_photo_id,
        :_destroy,
        photos: [],
        paint_usages_attributes: [:id, :user_paint_id, :_destroy]
      ]
    )

    # Remove blank string elements that Rails adds when no new file selected
    params_hash[:project_updates_attributes]&.each_value do |attrs|
      if attrs[:photos].is_a?(Array)
        attrs[:photos].reject!(&:blank?)
        attrs.delete(:photos) if attrs[:photos].empty?
      end
    end

    params_hash
  end

  def set_current_user_paints
    if user_signed_in?
      # Get all paint IDs from project updates
      paint_ids = @project.project_updates
                          .joins(user_paints: :paint)
                          .distinct
                          .pluck('paints.id')

      # Load current user's paints for these specific paints
      @current_user_paints = current_user.user_paints
                                        .includes(:paint)
                                        .where(paint_id: paint_ids)
                                        .index_by(&:paint_id)
    end
  end
end
