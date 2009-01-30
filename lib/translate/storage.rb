class Translate::Storage
  attr_accessor :locale
  
  def initialize(locale)
    self.locale = locale.to_sym
  end
  
  def write_to_file
    File.open(file_path, "w") do |file|
      file.puts yaml
    end
  end
  
  private
  def yaml
    # Stringifying keys for prettier YAML
    messages = deep_stringify_keys({
      locale.to_s => I18n.backend.send(:translations)[locale]
    })
    # Using ya2yaml, if available, for UTF8 support
    messages.respond_to?(:ya2yaml) ? messages.ya2yaml(:escape_as_utf8 => true) : messages.to_yaml
  end
  
  def file_path
    File.join(Rails.root, "config", "locales", "#{locale}.yml")
  end
  
  def deep_stringify_keys(hash)
    hash.inject({}) { |result, (key, value)|
      value = deep_stringify_keys(value) if value.is_a? Hash
      result[(key.to_s rescue key) || key] = value
      result
    }
  end
end
