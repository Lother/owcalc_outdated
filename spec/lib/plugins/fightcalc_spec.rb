# encoding: utf-8
require 'cinch'
require 'nokogiri'
require_relative '../../../lib/plugins/fightcalc.rb'
require_relative '../../../lib/ruby-cache-0.3.0/lib/cache.rb'
#require_relative '../../../lib/plugins/erpk.rb'

describe FightCalc do
  
  before :all do
    #Erpk.initialize
    @bot = Cinch::Bot.new{ self.loggers.clear }
    FightCalc.send(:public, *FightCalc.protected_instance_methods)   
    @fightcalc = FightCalc.new(@bot)
  end


  context "parser" do

    before :each do
      # p Erpk.profile_cache
      Erpk ||= stub('Erpk')
      plato = {:user_name=>"Plato", :rank_star=>2, :rank_text=>"Captain",
        :strength=>1001.0, :rank_level=>20, :next_rank_points=>2108,
        :birth=>Time.parse('2007-06-04 00:00:00 +0800'),
        :rank_points=>9892, :level=>27, :experience_points=>10316,
        :first_friend=>"Juxiaoxiong", :presence=>"offline", :user_id=>2,
        :avatar=>"/2007/06/04/c81e728d9d4c2f636f067f89cc14862c.jpg",
        :citizenship=>"Switzerland", :location=>"Attica",
        :medals=>{:"Hard Worker"=>1, :"Congress Member"=>1,
          :"Country President"=>1, :"Media Mogul"=>142, :"Super Soldier"=>4
        }
      }
      Erpk.stub('profile_of').and_return(plato)
      Erpk.stub('search').and_return(2)
    end

    plato = { 
      :fights => 1,
      :user_id => 2,
      :user_name => 'Plato',
      :natural_enemy => nil,
      :next_rank => nil,
      :objective => nil,
      :rank_level => 20,
      :strength => 1001.0,
    }

    it 'should parse irc_nick and inputed names' do
      @fightcalc.parse('plato', []).should == plato
      @fightcalc.parse('someone', ['plato']).should == plato
    end

    it 'should parse id' do
      @fightcalc.parse('someone', '-i 2'.split).should == plato
    end

    it 'should parse -o option' do
      @fightcalc.parse('plato', '-o10').should == plato.merge({ objective: 10 })
    end

    it 'should parse -f option' do
      @fightcalc.parse('plato', '-f10').should == plato.merge({ fights: 10 })
    end
    
    it 'should parse -e option' do
      @fightcalc.parse('plato', '-e').should == plato.merge({ natural_enemy: true })
    end

    it 'should parse -N option' do
      @fightcalc.parse('plato', '-N').should == plato.merge({ next_rank: true })
    end

    it 'should parse -s option' do
      @fightcalc.parse('plato', '-s1').should == plato.merge({ strength: 1 })
    end

    it 'should parse -r option' do
      @fightcalc.parse('plato', '-r1').should == plato.merge({ rank_level: 1 })
    end

  end

  context 'when conflicted options' do

    example 'should error on -o1 -N' do
      expect{ @fightcalc.fc(msg, '-o1 -N') }.to raise_error
    end

    example 'should ignore -f on -o -f100' 
    example 'should ignore -f on -N -f100' 
    example 'should ignore -f on -e -f100' 

  end

end
