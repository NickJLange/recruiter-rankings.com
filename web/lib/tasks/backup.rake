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

    desc "Restore a database backup"
    task :restore, [:filename] => :environment do |t, args|
      filename = args[:filename]
      if filename.blank?
        puts "Error: filename is required. Usage: rake db:backup:restore[filename.sql.gz.enc]"
        exit 1
      end

      # Restore logic will be implemented here
      # 1. Download from storage
      # 2. Decrypt
      # 3. Gunzip and pg_restore
      puts "Restore logic for #{filename} not yet fully implemented in CLI helper."
      puts "Manual restore: openssl enc -d ... | gunzip | psql ..."
    end
  end
end
