# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :authenticate_user!

  XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  # XLSX files are ZIP archives; magic bytes are PK\x03\x04
  XLSX_MAGIC = "\x50\x4B\x03\x04"

  def index
    @pagy, @uploads = pagy(policy_scope(Upload).includes(:file_attachment, :file_blob, :user)
                                                .order(created_at: :desc))
    authorize Upload
  end

  def create
    authorize Upload

    uploaded_file = params[:upload]&.fetch(:file, nil)

    unless uploaded_file.is_a?(ActionDispatch::Http::UploadedFile) &&
           uploaded_file.content_type == XLSX_MIME &&
           xlsx_magic_bytes?(uploaded_file.tempfile)
      redirect_to uploads_path, alert: "Only .xlsx files are accepted." and return
    end

    @upload = Upload.new(
      user: current_user,
      status: "pending"
    )
    @upload.file.attach(uploaded_file)

    if @upload.save
      BulkProductImportJob.perform_later(@upload.id)
      redirect_to uploads_path, notice: "File uploaded. Import is processing."
    else
      redirect_to uploads_path, alert: "Upload failed: #{@upload.errors.full_messages.join(', ')}"
    end
  end

  private

  def upload_params
    params.expect(upload: [:file])
  end

  def xlsx_magic_bytes?(tempfile)
    tempfile.rewind
    tempfile.read(4) == XLSX_MAGIC
  ensure
    tempfile.rewind
  end
end
