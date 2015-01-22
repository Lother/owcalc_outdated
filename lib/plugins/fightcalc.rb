# encoding: utf-8
require 'optparse'
class FightCalc

  include Cinch::Plugin
  set plugin_name: 'FightCalc'
  set help: '@fc [options]'
  set prefix: '@'

  def parse(nickname, args)
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: @fc [options]'

      opts.on('-i id', Integer, 'specify citizen id'     ) do |id|
        options[:user_id] = id 
      end
      opts.on('-s str', Float, 'specify strength points' ) do |str|
        options[:strength] = str 
      end
      opts.on('-r rank', Integer, 'specify rank level'   ) do |rank|
        options[:rank_level] = rank 
      end
      opts.on('-e', '10% bonus'                          ) do |e|
        options[:natural_enemy] = true 
      end
      opts.on('-b', 'booster 50%'                          ) do |b50|
        if options[:booster] == nil
          options[:booster] = 1.5
        else
          raise '-b & -B only exist one!'
        end
      end
      opts.on('-B', 'booster 100%'                         ) do |b100|
        if options[:booster] == nil
          options[:booster] = 2.0 
        else
          raise '-b & -B only exist one!'
        end
      end
      opts.on('-N', 'Next Rank'                          ) do |n|
        options[:next_rank] = true 
      end
      opts.on('-o obj', Integer, 'Objective influence'   ) do |obj|
        options[:objective] = obj
      end
      opts.on('-f fights', Integer, 'specify how many time to fight') do |f|
        options[:fights] = f
      end

    end

    user_name = parser.parse!(args).join(' ')
    user_name = user_name.empty? ? nickname : user_name

    id = options[:user_id] || Erpk.search(user_name)
    profile = Erpk.profile_of(id)

    fc_options = {
      :user_id       => profile[:user_id],
      :lv100up       => profile[:level]>= 100,
      :strength      => profile[:strength],
      :rank_level    => profile[:rank_level],
      :user_name     => profile[:user_name],
      :next_rank_points => profile[:next_rank_points],
      :fights        => 1,
      :objective     => nil,
      :next_rank     => nil,
      :natural_enemy => nil
    }.merge! options

    return fc_options
  end

  COLOR_CODE = [10, 9, 3, 8, 7, 4, 5, 10]
  
  def inf_objective(influence, objective)

    if objective > 999999999999 or objective < 0
      raise 'option -o is not in range'
    end

    inf_str = "輸出#{objective} 需要"
    influence.each_with_index do |inf,index|
      if objective % inf != 0
        inf = 1 + (objective / inf)
      else
        inf = objective / inf 
      end
      inf_str += "\x3#{COLOR_CODE[index]}"
      inf_str += "[Q#{index}]#{inf.ceil} "
    end      

    return inf_str
  end

  def inf_next_level(influence, remain_point)
    inf_str = '離升軍階'
		influence.each_with_index do |inf, index|
			inf_str += "\x3#{COLOR_CODE[index]}[Q#{index}]"
      inf_str += "#{(remain_point*10/inf.to_f.floor).ceil} "
		end
    return inf_str
  end

  def inf_str(influence, fights)
    inf_str = ''
    raise '-f 必須大於零' unless fights > 0
    influence.each_with_index do |inf,index|
      inf_str += "\x3#{COLOR_CODE[index]}[Q#{index}]"
      inf_str += "#{(inf * fights).floor} "
    end
    return inf_str
  end

  def inf_msg(options)
    influence = Erpk.fight_calc(*options.values_at(:rank_level, :strength, :lv100up),
                               (options[:booster]),
                               (options[:natural_enemy] unless options[:next_rank]))
    inf = if options[:objective] and !options[:next_rank]
            inf_objective(influence, options[:objective])
          elsif !options[:objective] and options[:next_rank]
            inf_next_level(influence, options[:next_rank_points])
          elsif options[:objective] and options[:next_rank]
            raise '-N and -o should not be used in the same time'
          else
            inf_str(influence, options[:fights])
          end
    return sprintf("%s(rank %d str %d%s%s%s%s%s)%s",
                   *options.values_at(:user_name, :rank_level, :strength),
                   (" #{options[:fights]}次" unless options[:fights] == 1),
                   (" 加上NE" if options[:natural_enemy]),
                   (" Lv100up" if options[:lv100up]),
                   (" +50%" if options[:booster] == 1.5),
                   (" +100%" if options[:booster] == 2.0),
                   inf)
                   
  end

  match(/fc(.*)/i, method: :fc)
  def fc(msg, opt)
    begin
      fc_options = parse(msg.user.nick, opt.split)
      msg.reply inf_msg(fc_options)
    rescue Exception => e
      msg.reply e.message
      puts e.message
      puts e.backtrace
    end
  end

end
