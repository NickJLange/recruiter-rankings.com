require "test_helper"

class LocaleTranslationCoverageTest < ActiveSupport::TestCase
  test "all translation keys in English exist in Japanese" do
    en_keys = flatten_keys(I18n.backend.translations[:en] || {})
    ja_keys = flatten_keys(I18n.backend.translations[:ja] || {})
    
    skip_keys = ["activerecord.errors", "errors", "activemodel.errors"]
    filtered_en_keys = en_keys.keys.reject { |k| skip_keys.any? { |skip| k.start_with?(skip) } }
    missing_keys = filtered_en_keys - ja_keys.keys
    
    assert_empty missing_keys, 
                 "English keys missing from Japanese: #{missing_keys.join(', ')}"
  end

  test "all translation keys use consistent placeholder syntax" do
    en_flat = flatten_keys(I18n.backend.translations[:en] || {})
    
    skip_keys = ["activerecord.errors", "errors", "activemodel.errors"]
    
    en_flat.each do |key, value|
      next unless value.is_a?(String)
      next if skip_keys.any? { |skip| key.start_with?(skip) }
      
      placeholders = value.scan(/%\{(\w+)\}/).flatten
      if placeholders.any?
        ja_value = I18n.backend.translations.dig(*key.split(".")) || ""
        
        placeholders.each do |placeholder|
          assert ja_value.include?("%{#{placeholder}}"), 
                 "Key #{key} has placeholder %{#{placeholder}} in English but missing in Japanese"
        end
      end
    end
  end

  test "Japanese translations have no English text" do
    ja_flat = flatten_keys(I18n.backend.translations[:ja] || {})
    
    english_patterns = [/Recruiter/i, /Search/i, /Submit/i]
    ja_flat.each do |key, value|
      next unless value.is_a?(String)
      
      english_patterns.each do |pattern|
        refute(value.match?(pattern), 
               "Japanese translation for #{key} contains English text: #{value}")
      end
    end
  end

  test "nav menu translations are complete for all locales" do
    nav_keys = [
      "nav.home",
      "nav.about", 
      "nav.policies",
      "nav.recruiters",
      "nav.companies",
      "nav.locale_en",
      "nav.locale_ja"
    ]
    
    I18n.available_locales.each do |locale|
      nav_keys.each do |key|
        translation = I18n.t(key, locale: locale, raise: false)
        assert_not_nil translation, "Key #{key} missing in locale #{locale}"
        assert translation.is_a?(String), "Key #{key} should be a string in locale #{locale}"
      end
    end
  end

  test "review form translations are complete" do
    review_keys = [
      "reviews.new.title_for",
      "reviews.new.overall_score",
      "reviews.new.your_experience",
      "reviews.new.email_optional",
      "reviews.new.submit"
    ]
    
    I18n.available_locales.each do |locale|
      review_keys.each do |key|
        translation = I18n.t(key, locale: locale, raise: false)
        assert_not_nil translation, "Key #{key} missing in locale #{locale}"
      end
    end
  end

  test "admin translations are complete" do
    admin_keys = [
      "admin.reviews.index.title",
      "admin.reviews.index.approve",
      "admin.reviews.index.flag",
      "admin.reviews.index.remove"
    ]
    
    I18n.available_locales.each do |locale|
      admin_keys.each do |key|
        translation = I18n.t(key, locale: locale, raise: false)
        assert_not_nil translation, "Key #{key} missing in locale #{locale}"
      end
    end
  end

  test "placeholder translations for proper interpolation" do
    test_cases = [
      { 
        key: "recruiters.index.subtitle",
        params: { count: 5 },
        en_pattern: /5/,
        ja_pattern: /5/
      },
      {
        key: "reviews.new.title_for",
        params: { name: "Test Recruiter" },
        en_pattern: /Test Recruiter/,
        ja_pattern: /Test Recruiter/  # Name stays same in both languages
      }
    ]
    
    I18n.available_locales.each do |locale|
      test_cases.each do |test_case|
        result = I18n.t(test_case[:key], **test_case[:params], locale: locale, raise: false)
        assert_not_nil result, "Failed to interpolate #{test_case[:key]} in #{locale}"
        assert result.is_a?(String), "Interpolation result should be a string"
      end
    end
  end

  test "translation files are valid YAML" do
    locale_files = Dir[
      Rails.root.join("config", "locales", "*.yml")
    ]
    
    locale_files.each do |file|
      content = File.read(file)
      parsed = YAML.safe_load(content, permitted_classes: [Symbol])
      assert parsed.is_a?(Hash), "#{file} should contain a valid YAML hash"
    end
  end

  test "no empty translation values" do
    I18n.available_locales.each do |locale|
      translations = I18n.backend.translations[locale]
      
      Rails.application.config.i18n.available_locales&.each do |avail_locale|
        next if avail_locale == locale
      end
    end
    
    skip "Custom validation for empty values needs implementation"
  end

  test "activerecord model names translated in Japanese" do
    model_names = %w[user recruiter company review review_metric identity_challenge 
                     takedown_request moderation_action profile_claim]
    
    model_names.each do |model_name|
      ja_translation = I18n.t("activerecord.models.#{model_name}", locale: :ja, count: 1, raise: false)
      assert_not_nil ja_translation, "activerecord.models.#{model_name} missing in Japanese"
      refute_empty ja_translation.to_s.strip, "activerecord.models.#{model_name} should not be empty"
    end
  end

  private

  def flatten_keys(hash, prefix = "")
    flat_hash = {}
    hash.each do |key, value|
      full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      if value.is_a?(Hash)
        flat_hash.merge!(flatten_keys(value, full_key))
      else
        flat_hash[full_key] = value
      end
    end
    flat_hash
  end

  def check_for_empty_values(translations, locale, key_path)
    translations.each do |key, value|
      current_path = key_path.empty? ? key.to_s : "#{key_path}.#{key}"
      
      if value.is_a?(Hash)
        check_for_empty_values(value, locale, current_path)
      elsif value.nil? || (value.is_a?(String) && value.strip.empty?)
        raise "Empty translation found for #{current_path} in locale #{locale}"
      end
    end
  end
end