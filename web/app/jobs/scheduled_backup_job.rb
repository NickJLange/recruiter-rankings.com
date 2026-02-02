class ScheduledBackupJob < ApplicationJob
  queue_as :default

  def perform(db_name: ENV['RENDER_DB_NAME'])
    return unless db_name.present?

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

    service.perform(db_name: db_name)
  rescue => e
    # We should notify here in Task 3.2
    Rails.logger.error "ScheduledBackupJob failed: #{e.message}"
    raise e
  end
end
