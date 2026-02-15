require "test_helper"
require "minitest/mock"
require "ostruct"

class BackupFlowTest < ActionDispatch::IntegrationTest
  setup do
    ENV['RENDER_DB_NAME'] = 'main-db'
    ENV['BACKUP_RETENTION_DAYS'] = '7'
  end

  test "scheduled backup job triggers backup service" do
    calls = []
    
    # Stub BackupService.new to return a dummy object that tracks calls
    stub_new = ->(*args) {
      mock_service = Object.new
      mock_service.define_singleton_method(:perform) do |**kwargs|
        calls << kwargs
        { status: :success, filename: 'f.enc', storage_path: 'p' }
      end
      mock_service
    }

    BackupService.stub :new, stub_new do
      ScheduledBackupJob.perform_now(db_name: 'main-db')
    end
    
    assert_equal [{db_name: 'main-db'}], calls
  end
end
