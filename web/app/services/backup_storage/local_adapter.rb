module BackupStorage
  class LocalAdapter
    def initialize(root_path: Rails.root.join('tmp', 'backups'))
      @root_path = Pathname.new(root_path)
      FileUtils.mkdir_p(@root_path) unless Dir.exist?(@root_path)
    end

    def upload(file_path, filename)
      dest_path = @root_path.join(filename)
      FileUtils.cp(file_path, dest_path)
      dest_path.to_s
    end

    def delete(filename)
      path = @root_path.join(filename)
      FileUtils.rm(path) if File.exist?(path)
    end

    def list
      Dir.glob(@root_path.join('*')).map { |f| File.basename(f) }
    end
  end
end
