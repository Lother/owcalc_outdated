require_relative "../../../lib/ruby-cache-0.3.0/lib/cache.rb"
require_relative "../../../lib/plugins/erpk.rb"

require 'nokogiri'

describe Erpk do

  before :all do
    Erpk.initialize 
  end

  describe "after initialization" do

     it "should have a profile cache" do
       Erpk.profile_cache.should be_a Cache
     end

  end

  let(:plato) { Erpk.profile_of(2) }
  let(:op8867555) { Erpk.profile_of(4407702) }

  describe ".profile_of" do

    context "2(plato)" do

      it "should return a Profile" do
        plato.class.should == Profile
      end
      
      it '.user_name should be "Plato"' do
        plato.user_name.should == "Plato"
      end

      it ".rank_point should be a number" do
        plato.rank_points.class.should == Fixnum
      end

    end

    context "4407702(op8867555)" do
      
      it '.user_name should be "op8867555"' do
        op8867555.user_name.should == "op8867555"
      end

    end

    context ".profile_cache" do

      it ".hits should be increasing" do
        hits = Erpk.profile_cache.statistics[2]
        Erpk.profile_of(2)
        Erpk.profile_cache.statistics[2].should > hits
      end

    end

    it "should raise error when an id doesn't existed" do
      Erpk.profile_of(0).should raise_error
    end

  end

end
