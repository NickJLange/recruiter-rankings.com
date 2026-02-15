require 'open3'

class BackupService
  class BackupError < StandardError; end

  def initialize(storage_adapter:, render_client: RenderApiClient.new, retention_days: 7)
    @storage_adapter = storage_adapter
    @render_client = render_client
    @retention_days = retention_days.to_i
  end

  def perform(db_name:)
    db_info = @render_client.find_database_by_name(db_name)
    raise BackupError, "Database #{db_name} not found on Render" unless db_info

    connection_string = db_info.dig('connectionInfo', 'externalConnectionString')
    raise BackupError, "Connection string not found for #{db_name}" unless connection_string

    timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
    filename = "backup-#{db_name}-#{timestamp}.sql.gz"
    temp_file = Rails.root.join('tmp', filename)

    begin
      # Use pg_dump piped to gzip — array-form avoids shell injection
      Open3.pipeline_r(
        ["pg_dump", connection_string],
        ["gzip"]
      ) do |output, wait_threads|
        File.open(temp_file.to_s, "wb") { |f| IO.copy_stream(output, f) }
        statuses = wait_threads.map(&:value)
        unless statuses.all?(&:success?)
          raise BackupError, "pg_dump/gzip pipeline failed"
        end
      end

      # Encrypt the file — array-form avoids shell injection
      encryption_key = ENV['BACKUP_ENCRYPTION_KEY']
      if encryption_key.present?
        encrypted_file = "#{temp_file}.enc"
        _stdout, stderr, status = Open3.capture3(
          "openssl", "enc", "-aes-256-cbc", "-salt", "-pbkdf2",
          "-in", temp_file.to_s, "-out", encrypted_file.to_s,
          "-k", encryption_key
        )

        unless status.success?
          raise BackupError, "Encryption failed: #{stderr}"
        end

        FileUtils.rm(temp_file)
        temp_file = encrypted_file
        filename = "#{filename}.enc"
      end

      # Upload
      storage_path = @storage_adapter.upload(temp_file, filename)

      # After successful upload, prune old backups
      prune(db_name)

      BackupMailer.success_notification(filename, storage_path).deliver_later

      { status: :success, filename: filename, storage_path: storage_path }
    rescue => e
      BackupMailer.failure_notification(e.message).deliver_later
      Rails.logger.error "BackupService Error: #{e.message}"
      raise e
    ensure
      FileUtils.rm(temp_file) if File.exist?(temp_file)
    end
  end

  def prune(db_name)
    prefix = "backup-#{db_name}-"
    cutoff = Time.now.utc - (@retention_days * 24 * 60 * 60)
    
    @storage_adapter.list.each do |filename|
      next unless filename.start_with?(prefix)
      
      # Extract timestamp: backup-db_name-YYYYMMDDHHMMSS.sql.gz.enc
      timestamp_str = filename[prefix.length, 14]
      begin
        timestamp = Time.utc(*timestamp_str.unpack('A4A2A2A2A2A2'))
        if timestamp < cutoff
          @storage_adapter.delete(filename)
        end
      rescue => e
        Rails.logger.warn "Failed to parse timestamp from #{filename}: #{e.message}"
      end
    end
  end
end