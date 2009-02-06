require 'yaml'

class Hash
  def deep_merge(other)
    # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
    merger = proc { |key, v1, v2| (Hash === v1 && Hash === v2) ? v1.merge(v2, &merger) : v2 }
    merge(other, &merger)
  end

  def set(keys, value)
    key = keys.shift
    if keys.empty?
      self[key] = value
    else
      self[key] ||= {}
      self[key].set keys, value
    end
  end
end

namespace :translate do
  desc "Show I18n keys that are missing in the config/locales/default_locale.yml YAML file"
  task :lost_in_translation => :environment do
    LOCALE = I18n.default_locale
    keys = []; result = []; locale_hash = {}
    Dir.glob(File.join("config", "locales", "**","#{LOCALE}.yml")).each do |locale_file_name|
      locale_hash = locale_hash.deep_merge(YAML::load(File.open(locale_file_name))[LOCALE])
    end
    lookup_pattern = Translate::Keys.new.send(:i18n_lookup_pattern)
    Dir.glob(File.join("app", "**","*.{rb,rhtml}")).each do |file_name|
      File.open(file_name, "r+").each do |line|
        line.scan(lookup_pattern) do |key_string|
          result << "#{key_string} in \t  #{file_name} is not in any locale file" unless key_exist?(key_string.first.split("."), locale_hash)
        end
      end
    end
    puts !result.empty? ? result.join("\n") : "No missing translations for locale: #{LOCALE}"
  end

  def key_exist?(key_arr,locale_hash)
    key = key_arr.slice!(0)
    if key
      key_exist?(key_arr, locale_hash[key]) if (locale_hash && locale_hash.include?(key))
    elsif locale_hash
      true
    end
  end

  desc "Merge I18n keys from log/translations.yml into config/locales/*.yml (for use with the Rails I18n TextMate bundle)"
  task :merge_keys => :environment do
    I18n.backend.send(:init_translations)
    new_translations = YAML::load(IO.read(File.join(Rails.root, "log", "translations.yml")))
    raise("Can only merge in translations in single locale") if new_translations.keys.size > 1
    locale = new_translations.keys.first

    overwrites = false
    Translate::Keys.new.send(:extract_i18n_keys, new_translations[locale]).each do |key|
      new_text = key.split(".").inject(new_translations[locale]) { |hash, sub_key| hash[sub_key] }
      existing_text = I18n.backend.send(:lookup, locale.to_sym, key)
      if existing_text && new_text != existing_text        
        puts "ERROR: key #{key} already exists with text '#{existing_text.inspect}' and would be overwritten by new text '#{new_text}'. " +
          "Set environment variable OVERWRITE=1 if you really want to do this."
        overwrites = true
      end
    end

    if !overwrites || ENV['OVERWRITE']
      I18n.backend.store_translations(locale, new_translations[locale])
      Translate::Storage.new(locale).write_to_file
    end
  end
end
