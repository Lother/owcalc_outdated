class Shuffler
  include Cinch::Plugin
  set plugin_name: "Shuffler", help: "@roll [max]"
  set prefix: "@"
  match(/roll(.*)/i)

  def execute(msg, max)
    begin
      unless max == ""
        max = max.scan(/(\d+)/).flatten!
        unless max
          raise "max must be a number."
        end
        max = max[0].to_i
      end  
      max = 100	if max == ""
      unless max < 99999 and max >0
        raise "#{max} must be a integer between 0 and 99999."
      end
      msg.reply "#{msg.user.nick} got #{Random.rand(max)+1}."
    rescue Exception => e
      msg.reply e.message
    end
  end
end
