namespace :db do
  namespace :backup do
    desc "Create a database backup"
    task create: :environment do
      db_name = ENV['DB_NAME'] || ENV['RENDER_DB_NAME']
      if db_name.blank?
        puts "Error: DB_NAME or RENDER_DB_NAME must be set"
        exit 1
      end

      puts "Starting backup for #{db_name}..."

      # Use the same logic as the job, but we can call it directly
      storage_adapter = if ENV['AWS_BUCKET'].present?
        BackupStorage::S3Adapter.new(
          bucket: ENV['AWS_BUCKET'],
          region: ENV['AWS_REGION'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          endpoint: ENV['AWS_ENDPOINT']
        )
      else
        BackupStorage::LocalAdapter.new
      end

      service = BackupService.new(
        storage_adapter: storage_adapter,
        retention_days: ENV['BACKUP_RETENTION_DAYS'] || 7
      )

      result = service.perform(db_name: db_name)
      puts "Backup completed successfully: #{result[:filename]}"
      puts "Stored at: #{result[:storage_path]}"
    end

    desc "Restore a database backup from R2. Usage: rake 'db:backup:restore[s3_key,target_db_url]'"
    task :restore, [:s3_key, :target_db_url] => :environment do |_t, args|
      require "shellwords"

      s3_key        = args[:s3_key].presence
      target_db_url = args[:target_db_url].presence || ENV["DATABASE_URL"]

      unless s3_key
        abort "Error: s3_key required.\n" \
              "Usage: rake 'db:backup:restore[backup-YYYYMMDD-HHMMSS.sql.gz,postgres://user:pass@host/db]'"
      end
      abort "Error: target_db_url required (or set DATABASE_URL)" unless target_db_url

      bucket       = ENV.fetch("R2_BUCKET")       { abort "Error: R2_BUCKET must be set" }
      endpoint_url = ENV.fetch("R2_ENDPOINT_URL") { abort "Error: R2_ENDPOINT_URL must be set" }

      # Map R2_* credential names to the AWS_* names the aws CLI expects
      ENV["AWS_ACCESS_KEY_ID"]     = ENV["R2_ACCESS_KEY_ID"]     if ENV["R2_ACCESS_KEY_ID"]
      ENV["AWS_SECRET_ACCESS_KEY"] = ENV["R2_SECRET_ACCESS_KEY"] if ENV["R2_SECRET_ACCESS_KEY"]
      ENV["AWS_DEFAULT_REGION"]    = "auto"

      redacted_url = target_db_url.sub(%r{:[^:@/]+@}, ":***@")
      puts "Downloading s3://#{bucket}/#{s3_key} and restoring to #{redacted_url} ..."

      restore_cmd = "aws s3 cp s3://#{Shellwords.escape("#{bucket}/#{s3_key}")} -" \
                    " --endpoint-url #{Shellwords.escape(endpoint_url)}" \
                    " | gunzip | psql #{Shellwords.escape(target_db_url)}"
      system(restore_cmd) or abort("Restore failed")

      puts "\nVerifying row counts:"
      %w[experiences recruiters users].each do |table|
        count = `psql #{Shellwords.escape(target_db_url)} -t -A -c "SELECT COUNT(*) FROM #{table};"`.strip
        puts "  #{table}: #{count}"
      end

      puts "\nRestore complete."
    end
  end
end
