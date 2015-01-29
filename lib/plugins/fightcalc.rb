# encoding: utf-8
require 'optparse'
class FightCalc

  include Cinch::Plugin
  set plugin_name: 'FightCalc'
  set help: '@fc [options]'
  set prefix: '@'
  Symbol = {
    "T" => 1000000000000,
    "G" => 1000000000,
    "M" => 1000000,
    "k" => 1000
  }
  def parse(nickname, args)
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: @fc [options]'

      opts.on('-h', '@fc help'     ) do |x|
        raise "@fc [-s strength] [-r rank] [-e] [-b|-B] [-N|-t|-o damage|-f fights] [-i userNo|username]\n"+
              "-e:加上NE, -b:+50%, -B:+100%, -N:下一軍階, -t:下一TP章, -o:輸出傷害, -f:次數"
      end
      opts.on('-i id', Integer, 'specify citizen id'     ) do |id|
        options[:user_id] = id 
      end
      opts.on('-s str', Float, 'specify strength points' ) do |str|
        options[:strength] = str 
      end
      opts.on('-r rank', Integer, 'specify rank level'   ) do |rank|
        if options[:next_rank]
          raise '-r and -N should not be used in the same time'
        end
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
        if options[:rank_level]
          raise '-r and -N should not be used in the same time'
        end
        if options[:next_tp] or options[:objective] or options[:fights] 
          raise '-f, -N ,-o and -t should not be used in the same time'
        end
        options[:next_rank] = true 
      end
      opts.on('-t', 'Next TP'                          ) do |t|
        if options[:next_rank] or options[:objective] or options[:fights]
          raise '-f, -N ,-o and -t should not be used in the same time'
        end
        options[:next_tp] = true 
      end
      opts.on('-o obj', String, 'Objective influence'   ) do |obj|
        if options[:next_tp] or options[:next_rank] or options[:fights]
          raise '-f, -N ,-o and -t should not be used in the same time'
        end
        data = obj.match('([0-9.]+)([kMGTPEZY]?)') 
        dec = data[1].to_f
        if data[2] !=""
          dec *= Symbol[data[2]]
        end
        options[:objective] = Integer(dec)
      end
      opts.on('-f fights', Integer, 'specify how many time to fight') do |f|
        if options[:next_tp] or options[:next_rank] or options[:objective]
          raise '-f, -N ,-o and -t should not be used in the same time'
        end
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
      :next_tp_points   => profile[:next_tp_points],
      :fights        => 1,
      :objective     => nil,
      :next_rank     => nil,
      :natural_enemy => nil
    }.merge! options

    return fc_options
  end

  COLOR_CODE = [10, 9, 3, 8, 7, 4, 5, 10]
  
  def inf_objective(influence, objective)

    inf_str = "輸出#{objective} 需要"
    influence.each_with_index do |inf,index|
      if objective % inf != 0
        inf = 1 + (objective / inf)
      else
        inf = objective / inf 
      end
      inf_str += "\x3#{COLOR_CODE[index]}"
      inf_str += "[Q#{index}]#{Integer(inf)} "
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

  def inf_next_tp(influence, remain_point)
    inf_str = '離TP獎章'
		influence.each_with_index do |inf, index|
			inf_str += "\x3#{COLOR_CODE[index]}[Q#{index}]"
      inf_str += "#{(remain_point/inf.to_f.floor).ceil} "
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
    inf = if options[:objective] 
            inf_objective(influence, options[:objective])
          elsif options[:next_rank]
            inf_next_level(influence, options[:next_rank_points])
          elsif options[:next_tp]
            if options[:next_tp_points]
              inf_next_tp(influence, options[:next_tp_points])
            else
              raise 'no any tp point'
            end
          else
            inf_str(influence, options[:fights])
          end
    return options[:user_name]+sprintf("(rank %d str %d%s%s%s%s%s)%s",
                   *options.values_at( :rank_level, :strength),
                   (" #{options[:fights]}次" unless options[:fights] == 1),
                   (" 加上NE" if options[:natural_enemy]),
                   (" Lv100up" if options[:lv100up]),
                   (" +50%" if options[:booster] == 1.5),
                   (" +100%" if options[:booster] == 2.0),
                   inf).gsub(/(\d)(?=(\d\d\d)+\b)/,'\1,')

                   
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
