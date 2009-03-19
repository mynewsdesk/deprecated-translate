class Translate::Log
  attr_accessor :from_locale, :to_locale, :from_texts
  
  def initialize(from_locale, to_locale, from_texts)
    self.from_locale = from_locale
    self.to_locale = to_locale
    self.from_texts = from_texts
  end
  
  def write_to_file
    file = Translate::File.new(file_path)
    current_texts = File.exists?(file_path) ? file.read : {}
    current_texts.merge!(from_texts)
    file.write(current_texts)
  end

  private
  def file_path
    File.join(Rails.root, "config", "locales", "log", "from_#{from_locale}_to_#{to_locale}.yml")
  end
end
