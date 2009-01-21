require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TranslateController do
  describe "index" do
    before(:each) do
      controller.stub!(:per_page).and_return(1)
      I18n.backend.stub!(:translations).and_return(i18n_translations)
      I18n.backend.instance_eval { @initialized = true }
      keys = mock(:keys)
      keys.should_receive(:files).and_return(files)
      keys.stub!(:i18n_keys).and_return(['vendor.foobar'])
      Translate::Keys.should_receive(:new).and_return(keys)
      I18n.stub!(:valid_locales).and_return([:en, :sv])
      I18n.stub!(:default_locale).and_return(:sv)
    end
    
    it "shows sorted paginated english keys from lookup and YAML files by default" do
      get_page :index
      assigns(:from_locale).should == :sv
      assigns(:to_locale).should == :en
      assigns(:files).should == files
      assigns(:paginated_keys).should == ['articles.new.page_title']
    end

    it "can be paginated with the page param" do
      get_page :index, :page => 3
      assigns(:files).should == files
      assigns(:paginated_keys).should == ['home.page_title']      
    end
    
    it "accepts a key_pattern param with key_type=starts_with" do
      get_page :index, :key_pattern => 'general', :key_type => 'starts_with'
      assigns(:files).should == files
      assigns(:paginated_keys).should == ['general.back']
      assigns(:total_entries).should == 1
    end

    it "accepts a key_pattern param with key_type=contains" do
      get_page :index, :key_pattern => 'page_title', :key_type => 'contains'
      assigns(:files).should == files
      assigns(:total_entries).should == 2
      assigns(:paginated_keys).should == ['articles.new.page_title']
    end

    it "accepts a filter=untranslated param" do
      get_page :index, :filter => 'untranslated'
      assigns(:total_entries).should == 3
      assigns(:paginated_keys).should == ['articles.new.page_title']
    end
    
    it "accepts a filter=translated param" do
      get_page :index, :filter => 'translated'
      assigns(:total_entries).should == 1
      assigns(:paginated_keys).should == ['vendor.foobar']
    end

    def i18n_translations
      HashWithIndifferentAccess.new({
        :en => {
          :vendor => {
            :foobar => "Foooo"
          }
        }
      })
    end
    
    def files
      HashWithIndifferentAccess.new({
        :'home.page_title' => ["app/views/home/index.rhtml"],
        :'general.back' => ["app/views/articles/new.rhtml", "app/views/categories/new.rhtml"],
        :'articles.new.page_title' => ["app/views/articles/new.rhtml"]
      })
    end
  end
  
  describe "translate" do
    it "should store translations to I18n backend and then write them to a YAML file" do
      I18n.backend.should_receive(:store_translations).with(:en, {
        :articles => {
          :new => {
            :title => "New Article"
          }
        },
        :category => "Category"
      })
      storage = mock(:storage)
      storage.should_receive(:write_to_file)
      Translate::Storage.should_receive(:new).with(:en).and_return(storage)
      post :translate, "key" => {'articles.new.title' => "New Article", "category" => "Category"}
      response.should be_redirect
    end
  end
  
  def get_page(*args)
    get(*args)
    response.should be_success
  end
end
