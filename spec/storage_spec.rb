require 'fileutils'
require File.dirname(__FILE__) + '/spec_helper'

describe Translate::Storage do
  describe "write_to_file" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end

    after(:each) do
      FileUtils.rm(file_path)
    end
    
    it "writes all I18n messages for a locale to YAML file" do
      I18n.backend.should_receive(:translations).and_return(translations)
      @storage.stub!(:file_path).and_return(file_path)
      @storage.write_to_file
      load_yaml(file_path).should == @storage.send(:deep_stringify_keys, translations)
    end

    def load_yaml(filename)
      YAML::load(IO.read(filename))
    end
    
    def file_path
      File.join(File.dirname(__FILE__), "files", "en.yml")
    end
    
    def translations
      {
        :en => {
          :article => {
            :title => "One Article"
          },
          :category => "Category"
        }
      }
    end
  end
  
  describe "deep_stringify_keys" do
    before(:each) do
      @storage = Translate::Storage.new(:en)
    end

    it "should convert all keys in a hash to strings" do
      @storage.send(:deep_stringify_keys, {
        :en => {
          :article => {
            :title => "One Article"
          },
          :category => "Category"
        }
      }).should == {
        "en" => {
          "article" => {
            "title" => "One Article"
          },
          "category" => "Category"
        }
      }
    end
  end
end
