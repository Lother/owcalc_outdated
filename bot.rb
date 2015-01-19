$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require "cinch"
require 'yaml'
require 'optparse'
require_relative "./lib/plugins.rb"

options = {}
parser = OptionParser.new do |opt|
  opt.on('-n', 'do not run the bot') { |r|
    options[:norun] = true }
  opt.on('-c config') { |c| options[:config_file] = c }
  opt.on('-e environment') { |e| options[:environment] = e }
end

parser.parse!(ARGV)

options = {
  config_file: 'configs/config.yml',
  environment: 'production'
}.merge(options)

$config = YAML.load_file(options[:config_file])[options[:environment]]

bot = Cinch::Bot.new do

  File.open("configs/binding.yaml","r") { |f| @nick_binding = YAML.load(f.read) }
  File.open("configs/id_cache.yaml","r") { |f| @id_cache = YAML.load(f.read) }
  Erpk.initialize(nil, @id_cache, @nick_binding)

  configure do |c|
    c.nick = $config['nick']
    c.server = $config['server']
    c.plugins.plugins = [FightCalc, ErpkToolbox, Shuffler, AdminToolbox]
  end

  on :connect do
    bot.privmsg "nickserv", "identify #{$config['password']}"
    $config['channels'].each { |ch| bot.join(ch) }
  end

  def save
    begin
      File.open("configs/binding.yaml","w") { |f| f.puts Erpk.nick_binding.to_yaml  }
      File.open("configs/id_cache.yaml","w") { |f| f.puts Erpk.id_cache.to_yaml }
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

end

bot.start unless options[:norun]
