class BackupMailer < ApplicationMailer
  def success_notification(filename, storage_path)
    @filename = filename
    @storage_path = storage_path
    mail(to: ENV.fetch("MAILER_ADMIN", "admin@example.com"), subject: "Database Backup Success: #{filename}")
  end

  def failure_notification(error_message)
    @error_message = error_message
    mail(to: ENV.fetch("MAILER_ADMIN", "admin@example.com"), subject: "Database Backup FAILURE")
  end
end
