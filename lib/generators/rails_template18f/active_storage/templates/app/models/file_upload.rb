class FileUpload < ApplicationRecord
  belongs_to :record, polymorphic: true
  has_one_attached :file

  delegate :open, :content_type, to: :file

  validates_presence_of :file
  validates_inclusion_of :scan_status, in: %w[uploaded scan_failed scanned quarantined]

  after_commit :scan

  def clean?
    scan_status == "scanned"
  end

  def filename
    file.filename.to_s
  end

  private

  def scan
    FileScanJob.perform_later self
  end
end
