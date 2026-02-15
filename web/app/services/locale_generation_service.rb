require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class LocaleGenerationService
  class TranslationError < StandardError; end

  def initialize(api_key: ENV['GEMINI_API_KEY'])
    @api_key = api_key
  end

  def sync(target_lang:, source_file: nil, target_file: nil)
    source_file ||= Rails.root.join('config', 'locales', 'en.yml')
    target_file ||= Rails.root.join('config', 'locales', "#{target_lang}.yml")

    source_data = YAML.load_file(source_file)['en']
    target_data = File.exist?(target_file) ? (YAML.load_file(target_file)[target_lang.to_s] || {}) : {}

    missing_keys = find_missing_keys(source_data, target_data)

    if missing_keys.any?
      puts "Found #{missing_keys.size} missing keys for #{target_lang}. Translating..."
      
      # If no API key, we'll just mock it for now to avoid blocking
      if @api_key.blank?
        puts "Warning: No GEMINI_API_KEY found. Using placeholders."
        translations = mock_translations(missing_keys, target_lang)
      else
        translations = translate_batch(missing_keys, target_lang)
      end
      
      # Smart merge: target_data is updated with translations for missing keys
      merged_data = deep_merge(target_data, translations)
      
      # Ensure the output is sorted and clean
      output = { target_lang.to_s => merged_data }
      File.write(target_file, output.to_yaml)
      puts "Successfully updated #{target_file}"
    else
      puts "No missing keys found for #{target_lang}."
    end
  end

  private

  def mock_translations(missing_keys, target_lang)
    mocked = {}
    missing_keys.each do |key, value|
      mocked[key] = "[#{target_lang.upcase}] #{value}"
    end
    mocked
  end

  def find_missing_keys(source, target, prefix = [])
    missing = {}
    source.each do |key, value|
      full_key = prefix + [key]
      if value.is_a?(Hash)
        target_value = target[key] || {}
        missing.merge!(find_missing_keys(value, target_value, full_key))
      else
        unless target.has_key?(key)
          missing[full_key.join('.')] = value
        end
      end
    end
    missing
  end

  def translate_batch(keys_with_values, target_lang)
    prompt = <<~PROMPT
      You are a professional translator for a privacy-focused recruiting platform.
      Translate the following English strings into #{target_lang.upcase}.
      
      Instructions:
      1. Maintain the exact same YAML-like key structure.
      2. PRESERVE all interpolation variables like %{count}, %{name}, etc.
      3. Use a tone that is professional yet friendly.
      4. Return ONLY a JSON object mapping the keys to their translations.

      Strings to translate:
      #{keys_with_values.to_json}
    PROMPT

    response = call_gemini(prompt)
    JSON.parse(response)
  rescue => e
    raise TranslationError, "Failed to translate batch: #{e.message}"
  end

  def call_gemini(prompt)
    uri = URI.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { response_mime_type: "application/json" }
    }.to_json

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      # Extract text from candidate
      text = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
      text
    else
      raise TranslationError, "Gemini API error: #{response.body}"
    end
  end

  def deep_merge(target, source)
    source.each do |key_path, value|
      keys = key_path.split('.')
      current = target
      keys[0...-1].each do |k|
        current[k] ||= {}
        current = current[k]
      end
      current[keys.last] = value
    end
    target
  end
end
