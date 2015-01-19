class AdminToolbox

  include Cinch::Plugin
  set prefix: "@"
  
  $admin = []
  
  def initialize(*args)
    super
    Kernel.trap('INT') do 
      @bot.channels.each{ |ch| ch.part("maintainence mode") } 
      @bot.quit("maintainence mode")
    end
  end

  match(/auth (.+)/i, method: :auth)
  def auth(msg, pass)
    if pass == $config["admin_password"]
      $admin << msg.user
      msg.reply "you are now authorized"
    else
      msg.reply "authorize failed"
    end
  end
     
  def is_admin?(user)
    $admin.include? user
  end

  def need_admin(msg, &block)
    begin
      raise "not authorized" unless is_admin?(msg.user)
      yield
    rescue => e
      msg.reply e.message
      puts e.message
    end
  end

  match(/save/i, method: :save)
  def save(msg)
    need_admin(msg){ bot.save }
  end
  
  match(/join (.+)/i, method: :join)
  def join(msg, channel)
    need_admin(msg){ bot.join channel }
  end
  
  match(/part (\#[^ ]+)/i, method: :part)
  def part(msg, channel)
    need_admin(msg){ bot.part(channel) }
  end

  match(/quit/i, method: :quit)
  def quit(msg)
    need_admin(msg){ bot.quit }
  end

end
