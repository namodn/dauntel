class Logger

require 'lib/config.rb'

#
# Runs on startup
#
def initialize
	cfg = Config.new()
	@debugLog = cfg.get('debugLog')
	@accessLog = cfg.get('accessLog')
	@errorLog = cfg.get('errorLog')
end

#
# logger method - this handles logging in general
#
def puts(severity, log)
	if severity == 'access'
		fullFilename = @accessLog
	elsif severity == 'error'
		fullFilename = @errorLog
	elsif severity == 'debug'
		fullFilename = @debugLog
	end

	file = open(fullFilename, "a")
	file.puts "#{log}"
	file.close
end

#
# Save log in common log format
# http://www.w3.org/Daemon/User/Config/Logging.html#common-logfile-format
#
def clf(ip_addr, url)
	self.puts('access', "#{ip_addr} - - [DD/MMM/YYYY:HH:MM:SS -0800] \"GET #{url} 200\" \"User Agent\"")
end

end  # end class Logger

