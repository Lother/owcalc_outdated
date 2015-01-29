class Call_All
  include Cinch::Plugin
  set plugin_name: "Call_All", help: "@call"
  set prefix: "@"
  puts "TEST"
  match(/call(.*)/i)
  def exec(msg)
    puts "call"
    begin
      msg.reply "#{msg.channel}"
    rescue Exception => e
      msg.reply e.message
    end
  end
end
