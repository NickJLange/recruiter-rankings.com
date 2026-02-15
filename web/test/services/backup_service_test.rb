require "test_helper"
require "minitest/mock"
require "ostruct"

class BackupServiceTest < ActiveSupport::TestCase
  setup do
    @storage = BackupStorage::LocalAdapter.new(root_path: Rails.root.join('tmp', 'test_backups'))
    @render_client = Minitest::Mock.new
    @service = BackupService.new(storage_adapter: @storage, render_client: @render_client, retention_days: 1)
    
    ENV['BACKUP_ENCRYPTION_KEY'] = 'test_secret'
    
    # Cleanup test backups
    FileUtils.rm_rf(Rails.root.join('tmp', 'test_backups'))
    FileUtils.mkdir_p(Rails.root.join('tmp', 'test_backups'))
  end

  test "perform executes pg_dump, encrypts, and uploads" do
    db_info = { 
      'name' => 'main-db', 
      'connectionInfo' => { 'externalConnectionString' => 'postgres://user:pass@host:5432/db' } 
    }
    @render_client.expect :find_database_by_name, db_info, ['main-db']

    # Mocking Open3.capture3
    stub_capture3 = ->(cmd) {
      if cmd.include?('pg_dump')
        path = cmd.split('>').last.strip
        File.write(path, "fake dump")
      elsif cmd.include?('openssl')
        out_path = cmd.match(/-out ([^\s]+)/)[1]
        File.write(out_path, "fake encrypted")
      end
      ["", "", OpenStruct.new(success?: true)]
    }

    Open3.stub :capture3, stub_capture3 do
      FileUtils.stub :rm, nil do
        # Stub BackupMailer to avoid background job issues in unit test
        mock_mail = Minitest::Mock.new
        mock_mail.expect :deliver_later, nil
        
        BackupMailer.stub :success_notification, mock_mail do
          result = @service.perform(db_name: 'main-db')
          assert_equal :success, result[:status]
          assert result[:filename].end_with?('.sql.gz.enc')
          assert File.exist?(result[:storage_path])
        end
      end
    end
  end

  test "prune deletes old backups" do
    # Create a mock storage with some files
    prefix = "backup-main-db-"
    now = Time.now.utc
    old_timestamp = (now - 2.days).strftime('%Y%m%d%H%M%S')
    new_timestamp = now.strftime('%Y%m%d%H%M%S')
    
    old_file = "#{prefix}#{old_timestamp}.sql.gz.enc"
    new_file = "#{prefix}#{new_timestamp}.sql.gz.enc"
    
    File.write(Rails.root.join('tmp', 'test_backups', old_file), "old content")
    File.write(Rails.root.join('tmp', 'test_backups', new_file), "new content")
    
    @service.prune('main-db')
    
    assert_equal [new_file], @storage.list
    assert_not File.exist?(Rails.root.join('tmp', 'test_backups', old_file))
    assert File.exist?(Rails.root.join('tmp', 'test_backups', new_file))
  end
end
