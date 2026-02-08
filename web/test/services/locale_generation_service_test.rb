require "test_helper"
require "minitest/mock"
require "tmpdir"

class LocaleGenerationServiceTest < ActiveSupport::TestCase
  # No DB or fixtures needed
  self.use_transactional_tests = false

  # Override fixtures to do nothing
  def setup_fixtures; end
  setup do
    @service = LocaleGenerationService.new(api_key: 'fake_key')
    @tmpdir = Dir.mktmpdir
    @source_file = File.join(@tmpdir, 'en.yml')
    @target_file = File.join(@tmpdir, 'test_ja.yml')

    # Write test source to temp file instead of clobbering real en.yml
    File.write(@source_file, { 'en' => { 'hello' => 'Hello', 'nested' => { 'world' => 'World' } } }.to_yaml)
  end

  test "sync identifies missing keys and updates target file" do
    # Target file is missing 'nested.world'
    File.write(@target_file, { 'test_ja' => { 'hello' => 'こんにちは' } }.to_yaml)

    mock_response = { 'nested.world' => '世界' }.to_json

    @service.stub :call_gemini, mock_response do
      @service.sync(target_lang: 'test_ja', source_file: @source_file, target_file: @target_file)
    end

    result = YAML.load_file(@target_file)['test_ja']
    assert_equal 'こんにちは', result['hello']
    assert_equal '世界', result['nested']['world']
  end

  teardown do
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end
end
