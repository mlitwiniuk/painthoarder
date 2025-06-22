class ProjectUpdatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_project_update, only: %i[edit update destroy]
  before_action :ensure_owner

  # GET /projects/:project_id/project_updates/new
  def new
    @project_update = @project.project_updates.build

    respond_to do |format|
      format.html { render layout: false if request.headers['Turbo-Frame'] }
      format.json
    end
  end

  # POST /projects/:project_id/project_updates
  def create
    permitted_params = project_update_params

    # Remove photo params since we handle them separately
    create_params = permitted_params.dup
    photos_to_add = create_params.delete(:photos)
    create_params.delete(:remove_photos)

    @project_update = @project.project_updates.build(create_params)

    respond_to do |format|
      if @project_update.save
        handle_new_photos!(permitted_params)
        set_primary_photo!
        format.html {
          if request.headers['Turbo-Frame']
            redirect_to @project, notice: "Update was successfully added."
          else
            redirect_to @project, notice: "Update was successfully added."
          end
        }
        format.json { render json: @project_update, status: :created }
      else
        format.html {
          render :new, status: :unprocessable_entity, layout: false if request.headers['Turbo-Frame']
        }
        format.json { render json: @project_update.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /projects/:project_id/project_updates/:id/edit
  def edit
    respond_to do |format|
      format.html { render layout: false if request.headers['Turbo-Frame'] }
      format.json
    end
  end

  # PATCH/PUT /projects/:project_id/project_updates/:id
  def update
    permitted_params = project_update_params
    # Handle photo operations before updating
    handle_photo_operations!(permitted_params)

    # Remove photo params since we handled them separately
    permitted_params.delete(:photos)
    permitted_params.delete(:remove_photos)

    respond_to do |format|
      if @project_update.update(permitted_params)
        set_primary_photo!
        format.html {
          if request.headers['Turbo-Frame']
            redirect_to @project, notice: "Update was successfully modified."
          else
            redirect_to @project, notice: "Update was successfully modified."
          end
        }
        format.json { render json: @project_update, status: :ok }
      else
        format.html {
          render :edit, status: :unprocessable_entity, layout: false if request.headers['Turbo-Frame']
        }
        format.json { render json: @project_update.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/project_updates/:id
  def destroy
    @project_update.destroy!

    respond_to do |format|
      format.html { redirect_to @project, status: :see_other, notice: "Update was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_project_update
    @project_update = @project.project_updates.find(params[:id])
  end

  def ensure_owner
    redirect_to projects_path, alert: "You don't have permission to access this project." unless current_user == @project.user
  end

  def handle_photo_operations!(permitted_params)
    # Remove selected photos
    if permitted_params[:remove_photos].present?
      permitted_params[:remove_photos].each do |attachment_id|
        next if attachment_id.blank?

        attachment = @project_update.photos_attachments.find_by(id: attachment_id)
        if attachment
          # If this is the primary photo, clear it first
          if @project_update.primary_photo == attachment
            @project_update.update(primary_photo: nil)
          end

          # If this is the project's cover photo, clear it first
          if @project.cover_photo && @project.cover_photo.blob_id == attachment_id
            @project.update!(cover_photo: nil)
          end

          attachment.purge
        end
      end
    end

    # Append new photos (don't replace existing ones)
    if permitted_params[:photos].present?
      new_photos = permitted_params[:photos].reject(&:blank?)
      new_photos.each do |photo|
        @project_update.photos.attach(photo)
      end
    end
  end

  def set_primary_photo!
    return if params[:project_update][:primary_photo_id].blank?

    attachment = @project_update.photos_attachments.find_by(id: params[:project_update][:primary_photo_id])
    return unless attachment

    @project_update.update(primary_photo: attachment)
  end

  def handle_new_photos!(permitted_params)
    # Add new photos for create action
    if permitted_params[:photos].present?
      new_photos = permitted_params[:photos].reject(&:blank?)
      new_photos.each do |photo|
        @project_update.photos.attach(photo)
      end
    end
  end

  def project_update_params
    params.require(:project_update).permit(
      :title,
      :description,
      :primary_photo_id,
      remove_photos: [],
      photos: [],
      paint_usages_attributes: [:id, :user_paint_id, :_destroy]
    )
  end
end
