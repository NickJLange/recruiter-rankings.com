require 'aws-sdk-s3'

module BackupStorage
  class S3Adapter
    def initialize(bucket:, region: ENV['AWS_REGION'] || 'us-east-1', access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'], endpoint: ENV['AWS_ENDPOINT'])
      @bucket_name = bucket
      @client = Aws::S3::Client.new(
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        endpoint: endpoint,
        force_path_style: endpoint.present? # Useful for S3-compatible providers like MinIO/R2
      )
      @resource = Aws::S3::Resource.new(client: @client)
      @bucket = @resource.bucket(@bucket_name)
    end

    def upload(file_path, filename)
      obj = @bucket.object(filename)
      obj.upload_file(file_path)
      obj.public_url
    end

    def delete(filename)
      @bucket.object(filename).delete
    end

    def list
      @bucket.objects.map(&:key)
    end
  end
end
