require "nokogiri"
require "open-uri"
module Erpk

end

class << Erpk

  attr_accessor :profile_cache 
  attr_accessor :id_cache
  attr_accessor :nick_binding
  #ERPK_URL="http://api.erpk.org"
  ERPK_SEARCH_URL = "http://www.erepublik.com/en/main/search/?q=" 
  Rank = {
    "Recruit" => 2,
    "Private" => 2,
    "Corporal" => 6,
    "Sergeant" => 10,
    "Lieutenant" => 14,
    "Captain" => 18,
    "Major" => 22,
    "Commander" => 26,
    "Lt Colonel" => 30,
    "Colonel" => 34,
    "General" => 38,
    "Field Marshal" => 42,
    "Supreme Marshal" => 46,
    "National Force" => 50,
    "World Class Force" => 54,
    "Legendary Force" => 58,
    "God of War" => 62 }
    
  def initialize(profile_cache = nil, id_cache = {}, nick_binding = {})
    @profile_cache = profile_cache || Cache.new(expiration: 120)
    @id_cache = id_cache
    @nick_binding = nick_binding
  end

  def search(name)
    binding_nick = name.downcase.to_sym
    name = if @nick_binding[binding_nick]
             @nick_binding[binding_nick] 
           else
             nick_normalize(name).to_sym
           end

    if @id_cache[name]
      return @id_cache[name]
    else
      return search_html(name.to_s)
    end
  end

  def bind_nick(nick, name)
    cached_nick = nick_normalize(nick).to_sym
    bind_nick = nick.downcase.to_sym
    @nick_binding[bind_nick] = if @id_cache[cached_nick]
                                 name
                               else
                                 profile_of(search_html(name))[:user_name]
                               end
    return true
  end

  def profile_of(id)
    unless @profile_cache[id]
      profile = get_porfile(id)
      @profile_cache[id]= profile
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

  private

  def nick_normalize(nick)
    return nick.downcase.gsub(/\[.+\]/,'').gsub(/(_)*$/,'').gsub(/(\_)+/,' ').gsub(/(\|.+)/,'').gsub(/ *$/,'').gsub(/^ */,'')
  end

  def search_html(username)
    unless username
      raise "user_name is not vaild." 
    end

    url = ERPK_SEARCH_URL + URI.escape(username, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    doc = Nokogiri::HTML open(url).read

    if doc.css('tr > td').empty?
      raise "unknown citizen name #{username}" 
    end

    #user_name = search_user_doc.css('tr>td>div>div>a.dotted').children
    #user_name = (user_name.class == Array)? (user_name[0].text):(user_name.text)
    #        p search_user_doc.css('tr>td>div>div>a.dotted')
    begin
      user = doc.css('tr>td>div>div>a.dotted') .attr('href').to_s.scan(/\d+/).first.to_i
      return user
    rescue
      raise "#{username} is not found"
    end
  end

  def get_porfile(id)
    begin
      return fetch_profile_page(id) 
    rescue Exception => e
      puts e.message
      puts e.backtrace
      #puts e.backtrace.inspect
    end
  end

  def fetch_profile_page(id)
    url = "http://www.erepublik.com/en/citizen/profile/"+id.to_s
    data = Nokogiri::HTML open(url).read

    profile = Profile.new
    profile[:rank_star] = data.css(".citizen_military > h4 > a").children.to_s.scan('*').size
    profile[:rank_text] = data.css(".citizen_military > h4 > a").children.to_s.gsub(/\**/,"").gsub(/\ $/,"")
    profile[:strength] = data.css(".citizen_military > h4")[0].content.gsub(/[\r|\t]/,"").gsub(/\,/,'').to_f
    profile[:rank_level] = Rank[profile[:rank_text]].to_i + profile[:rank_star]
    profile[:citizenship] = data.css('.citizen_info > a > img').last.attr('alt').to_s
    profile[:location] = data.css('.citizen_info > a').children[3].text.gsub(/ */,'')

    rank_points_full = data.css('div.stat>small>strong')[1].children.text.gsub(/[,| ]/,'').match(/(\d+)\/(\d+)/)
    profile[:next_rank_points] = rank_points_full[2].to_i - rank_points_full[1].to_i
    profile[:rank_points] = rank_points_full[1].to_i

    user_name = data.css('.citizen_profile_header>h2:has(span)').css('a').remove()
    user_name = data.css('.citizen_profile_header>h2:has(span)').text.gsub(/\n */,'').gsub(/ *\t *\t *$/,'').gsub(/\t*/,'').gsub(/ *$/,'')
    profile[:user_name] = (user_name.class == Array)? (user_name[0]):(user_name)

    profile[:birth] = Time.parse(data.css('.citizen_second>p').children.text)
    profile[:level] = data.css('div.citizen_experience>strong').children.to_s.to_i
    profile[:experience_points] = data.css('div.citizen_experience>div>p').text.gsub(/[,| ]/,'').match(/(\d+)/)[1].to_i
    profile[:first_friend] = if !data.css('div.citizen_activity>ul>li>a').first.nil?
                               data.css('div.citizen_activity>ul>li>a').first["title"]
                             else 
                               nil
                             end
    profile[:presence] = data.css('.citizen_presence>img').attr('alt').text
    profile[:user_id] = id

    medals = {}
    data.css('.achiev>li>.counter').each{|m| medals.store m.parent.css('strong').text.gsub(/\d*/,'').to_sym, m.text.to_i}
    profile[:medals] = medals

    avatar = data.css('div.citizen_profile_header>img').last.values.last.match(/Citizens(.+)_142x142\.jpg\)\;/)
    profile[:avatar] = 
      if avatar
        avatar[1] + ".jpg"
      else
        "Avatar not found"
      end

    return profile
  end

end

profile_args = [:user_name, :rank_star, :rank_text, :strength, :rank_level, :birth, :rank_points, :level, :experience_points, :first_friend, :presence, :user_id, :avatar, :citizenship, :location, :next_rank_points, :medals]
class Profile < Struct.new(*profile_args)
end
