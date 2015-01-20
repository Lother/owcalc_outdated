#  encoding: utf-8
class ErpkToolbox
  include Cinch::Plugin
  
  set plugin_name: "Toolbox"
  set prefix:"@"

  def parse_opts(nickname, args)
    options = {}
    parser = OptionParser.new do |opt|
      opt.on("-i id", "specify citizen id") do |id|
        options[:user_id]=id.to_i
      end
    end 

    user_name = parser.parse(args).join(" ")
    options[:user_name] = user_name.empty? ? nickname : user_name

    return options
  end

  def parse(nickname, args)
    options = parse_opts(nickname, args.split)
    profile = Erpk.profile_of(options[:user_id] || Erpk.search(options[:user_name]))
    return profile
  end

  Lookup_message_args = [:user_name, :user_id, :level, :experience_points, :citizenship, :location, :strength, :rank_level, :division, :first_friend]

  def lookup_message(profile)
    values=[]
    Lookup_message_args.each {|arg| values << profile[arg]}
	  return sprintf("%s[%d] Lv%d(%dXP) 國籍 %s 位於 %s 力量%d 軍階Lv%d %s 第一個朋友%s 天數%s",
                   *values,
                   ((Time.new - profile[:birth])/86400).floor
                  )
	end

  def def_with_exception_hadler(name, &block)
    define_method name.to_sym do |proc|
      begin
        yield
      rescue Exception => e
        msg.reply e.message
        puts e.message
        puts e.backtrace
      end
    end
  end

  def handle_exception(msg, &block)
    begin
      yield
    rescue Exception => e
      msg.reply e.message
      bot.warn e.message
      bot.warn e.backtrace
    end
  end

  match(/(?:lookup|lp)(.*)/i, method: :lookup)
  def lookup(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      msg.reply lookup_message(profile) 
    end
  end

  match(/(?:h)(.+)/i, method: :command_help)
  def command_help(msg, args)
    handle_exception(msg) do
      msg.reply "command : @lp, @fc, @ln, @ow, @ava, @medal, @do, @link"
    end
  end
  
  match(/(?:donate|do)(.*)/i, method: :donate)
  def donate(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      msg.reply "#{profile[:user_name]}的捐贈頁面 http://www.erepublik.com/en/economy/donate-items/"+profile[:user_id].to_s
    end
  end

  match(/link(.*)/i, method: :link)
  def link(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      msg.reply "#{profile[:user_name]}的個人頁面 http://www.erepublik.com/en/citizen/profile/"+profile[:user_id].to_s
    end
  end

  match(/(?:avatar|ava)(.*)/i, method: :avatar)
  def avatar(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      msg.reply "#{profile[:user_name]}的個人頭像 "+profile[:avatar].to_s
    end
  end

  match(/(?:medals|medal)(.*)/i, method: :medals)
  def medals(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      medal_msg = "#{profile[:user_name]}的獎牌們"
      profile[:medals].each do |medal, quanity|
        medal_msg += " #{medal.to_s}: #{quanity.to_i}"
      end
      msg.reply medal_msg
    end
  end
  
  match(/ow(.*)/, method: :ow_calc)
  def ow_calc(msg, args)
    handle_exception(msg) do
      profile = parse(msg.user.nick, args)
      ow_profile = Erpk.profile_of(1772310) 
      ow_inf = Erpk.fight_calc(ow_profile.rank_level, ow_profile.strength)[0]
      inf = Erpk.fight_calc(profile.rank_level, profile.strength)[0]
      str = sprintf("%s(rank %d str %d)",
                    profile.user_name,
                    profile.rank_level,
                    profile.strength
                   )
      str += sprintf("的空手影響力(#{inf.floor})約等於%g個老王(#{ow_inf})",
                     (inf.floor.to_f/ow_inf.floor.to_f).round(5)
                    )
      msg.reply str
    end
  end

  match(/(?:ln|reg|bind)(.+)/i, method: :nick_bind)
  def nick_bind(msg, args)
    handle_exception(msg) do
      options = parse_opts(msg.user.nick, args.split)
      if Erpk.bind_nick(msg.user.nick, options[:user_name])
        msg.reply(msg.user.nick+" 以連結到 "+options[:user_name])
      end
      #msg.reply "Not Implentment Yet"+profile[:user_name].to_s
    end
  end

end
