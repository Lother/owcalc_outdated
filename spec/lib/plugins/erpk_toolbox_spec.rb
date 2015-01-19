require "cinch"
require "nokogiri"
require "optparse"
#require_relative '../../../lib/plugins/erpk.rb'
require_relative '../../../lib/ruby-cache-0.3.0/lib/cache.rb'
require_relative '../../../lib/plugins/erpk_toolbox.rb'


describe "ErpkToolbox" do

  before :all do
    @bot = Cinch::Bot.new{ self.loggers.clear }
  end
  
  before :each do
    Erpk ||= stub('Erpk')
    Erpk.stub('profile_of')
    ErpkToolbox.send(:public, *ErpkToolbox.protected_instance_methods)   
    @toolbox = ErpkToolbox.new(@bot)
  end

  context "#parse_opt" do
    

    it "should take a specify id" do
      options = @toolbox.parse_opts("nick", "-i 100".split)
      options[:user_id].should == 100
      Erpk.should_receive(:profile_of).with(100)
      profile = @toolbox.parse("someone", "-i 100")
    end
    
    it "should take nickname without argv" do
      @toolbox.parse_opts("nick", "".split)[:user_name].should == "nick"
    end
    
    it "should take nickname with space-only input" do
      @toolbox.parse_opts("nick", " ".split)[:user_name].should == "nick"
    end

    it "should take a username if somebody give it one" do
      @toolbox.parse_opts("nick", "username".split)[:user_name].should == "username"
    end

    it "should raise an error when missing arguments " do

      expect{ @toolbox.parse_opts("nick", "-i".split) }.to raise_error do |error|
        error.message.should match("missing argument")
      end

    end

  end

  context "#parse" do

    it "should return a correct Profile"
    
  end

end
