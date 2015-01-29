class MailNotify
  require 'gmail'
  include Cinch::Plugin
  set plugin_name: "MailNotify", help: "mail to Lother"
  set prefix:""
  match(/(.*lother.*)/i)
  def execute(msg, args)
    begin
      if (msg.user!='lother' or msg.user!='ow_calc_v3')
        puts args
        gmail = Gmail.new("keven01234", "")
        gmail.deliver do
          to "lotherex+irc@gmail.com"
          subject "Notify!! #{msg.user} call you!"
          body "#{msg.time} \n#{args}"
        end
      end
    rescue Exception => e
      puts "[#{e.message}]"
    end
  end
end
