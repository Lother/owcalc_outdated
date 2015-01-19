require "open-uri"
require "json"

module Erpk

end	

class << Erpk

	attr_accessor :profile_cache 
	attr_accessor :id_cache
  attr_accessor :nick_binding_list
	ERPK_URL="http://api.erpk.org"

	def initialize(api_key, profile_cache = Cache.new(expiration: 120), id_cache = {}, nick_binding_list = {})
		@profile_cache = profile_cache 
		@id_cache = id_cache
		@api_key = api_key
    @nick_binding_list = nick_binding_list
	end
  
	def profile_of(id)
		unless @profile_cache[id]
			profile = open_json(ERPK_URL+"/citizen/profile/#{id}.json?key="+@api_key)
			@profile_cache[id]= profile.symbolize_keys!
		end
		return @profile_cache[id]
	end

  def fight_calc(rank, strength, natural_enemy = false)
    inf = []
    ne_bonus = natural_enemy ? 1.1 : 1.0
    [1,1.2,1.4,1.6,1.8,2,2.2,3].each do |q|
      inf << ((((rank.to_f-1)/20 + 0.3) * ((strength.to_f / 10) + 40)) * q * ne_bonus).floor
    end
    return inf
  end

  #
  # 1. nick_binding
  # 2. use nickname to search
  # 3. use api to search
  #
  def search(name)

    name = nick_normalize(name).to_sym
    name = @nick_binding_list[name] if @nick_binding_list[name]
      
    if @id_cache[name]
      return @id_cache[name]
    else
      return search_using_api(name.to_s)
    end
  end

  private

  def nick_normalize(nick)
    return nick.downcase.gsub(/\[.+\]/,'').gsub(/(_)*$/,'').gsub(/(\_)+/,' ').gsub(/(\|.+)/,'').gsub(/ *$/,'').gsub(/^ */,'')
  end
  #
  # search username form erpk api
  # return the first id
  # then save result to hash
  # (username.to_sym => id.to_sym)
  #

  def search_using_api(name)
    escaped_name = URI.escape(name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    result = open_json(ERPK_URL + "/citizen/search/#{escaped_name}/1.json?key=" + @api_key)
    if result and result != []
      result.each do |entry|
        @id_cache[entry["name"].to_sym] = entry["id"]
      end
      return result.first["id"]
    else
      raise "username #{name} is not found"
    end
  end


  def open_uri(uri)
    begin
      link = open(uri)
      return link
    rescue Exception => e
      return e
    end
  end

  def open_json(target)
    begin
      link = open(target)
      return JSON.parse(link.read)
    rescue Exception => e
      raise e.message
    end
  end

end
