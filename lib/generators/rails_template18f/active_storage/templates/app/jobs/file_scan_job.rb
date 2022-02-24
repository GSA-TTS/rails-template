class FileScanJob < ApplicationJob
  queue_as :default

  def perform(file_upload)
    return if file_upload.nil? || file_upload.clean?
    file_upload.open do |file|
      payload = {file: Faraday::Multipart::FilePart.new(
        file,
        file_upload.content_type,
        file_upload.filename
      )}
      response = connection.post("/scan", payload)
      if response.success?
        file_upload.update_columns scan_status: "scanned", updated_at: Time.now
      else
        logger.error "File Scan for #{file_upload.id} failed: #{response.body}"
        file_upload.update_columns scan_status: "quarantined", updated_at: Time.now
      end
    end
  rescue => ex
    file_upload&.update_columns scan_status: "scan_failed", updated_at: Time.now
    raise ex
  end

  def connection
    @connection ||= Faraday.new(
      url: ENV["CLAMAV_API_URL"],
      ssl: {verify: false}
    ) do |f|
      f.request :multipart
    end
  end
end
