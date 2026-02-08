namespace :i18n do
  desc "Generate missing translations for a specific language using LLM"
  task :generate, [:lang] => :environment do |t, args|
    lang = args[:lang]
    if lang.blank?
      puts "Error: language required. Usage: rake i18n:generate[ja]"
      exit 1
    end

    current_branch = `git rev-parse --abbrev-ref HEAD`.strip
    target_branch = "lang-#{lang}"

    puts "==> Starting generation for #{lang}..."
    
    # 1. Switch to language branch
    puts "--> Switching to #{target_branch}"
    unless system("git checkout #{target_branch}")
      puts "Error: Could not switch to #{target_branch}. Ensure it exists."
      exit 1
    end

    # 2. Merge main to get latest English keys
    puts "--> Merging main"
    system("git merge main --no-edit")

    # 3. Perform translation
    service = LocaleGenerationService.new
    service.sync(target_lang: lang)

    # 3.5 Sync to Jekyll
    Rake::Task["i18n:sync_jekyll"].invoke

    # 4. Commit changes
    puts "--> Committing changes"
    system("git add config/locales/#{lang}.yml ../site/_data/i18n/#{lang}.yml")
    system("git commit -m \"i18n: automated translation update for #{lang}\" --allow-empty")

    # 5. Switch back
    puts "--> Switching back to #{current_branch}"
    system("git checkout #{current_branch}")
    
    puts "==> Generation complete for #{lang}."
  end

  desc "Audit translations and report missing keys"
  task audit: :environment do
    source_file = Rails.root.join('config', 'locales', 'en.yml')
    source_data = YAML.load_file(source_file)['en']
    
    target_langs = %w[ja es fr ar]
    
    def find_missing(source, target, prefix = [])
      missing = []
      source.each do |key, value|
        full_key = prefix + [key]
        if value.is_a?(Hash)
          target_value = target[key] || {}
          missing += find_missing(value, target_value, full_key)
        else
          # Check both string and symbol keys
          unless target.has_key?(key.to_s) || target.has_key?(key.to_sym)
            missing << full_key.join('.')
          end
        end
      end
      missing
    end

    target_langs.each do |lang|
      target_file = Rails.root.join('config', 'locales', "#{lang}.yml")
      if File.exist?(target_file)
        begin
          target_data = YAML.load_file(target_file)[lang.to_s] || {}
          missing = find_missing(source_data, target_data)
          if missing.any?
            puts "❌ #{lang}: #{missing.size} keys missing"
            puts "   " + missing.take(5).join(', ') + (missing.size > 5 ? "..." : "")
          else
            puts "✅ #{lang}: complete"
          end
        rescue => e
          puts "❌ #{lang}: Error parsing file - #{e.message}"
        end
      else
        puts "❓ #{lang}: file missing"
      end
    end
  end

  desc "Synchronize Rails locales to Jekyll i18n data"
  task sync_jekyll: :environment do
    source_dir = Rails.root.join('config', 'locales')
    dest_dir = Rails.root.join('..', 'site', '_data', 'i18n')
    
    FileUtils.mkdir_p(dest_dir)
    
    Dir.glob(source_dir.join('*.yml')).each do |file|
      lang = File.basename(file, '.yml')
      data = YAML.load_file(file)[lang]
      # Jekyll usually wants keys directly without the lang prefix in some setups,
      # but let's check current format.
      File.write(dest_dir.join("#{lang}.yml"), data.to_yaml)
      puts "Synced #{lang}.yml to Jekyll"
    end
  end

  desc "Publish: Aggregate locales and embeddings"
  task publish: :environment do
    system("../scripts/publish.sh")
  end
end
