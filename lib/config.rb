class Config

#
# Runs on startup
#
def initialize
	configFile = 'etc/dauntel.cfg'
	@version = '0.3'
	loadConfig(configFile)
end

#
# config method, define all configurable settings
#
def loadConfig(configFile)
	# defaults, in case the config file is non-existant or corrupt
	@hostname, @port, @documentRoot, @indexFiles, @mimeFile, 
	@accessLog, @errorLog, @debugLog, @loadMod = 
	'localhost', '8080', 'htdocs/', ['index.html', 'index.htm'], 
	'etc/mime.types', 'log/access.log', 'log/error.log', 'log/debug.log', []

	config = open(configFile, "r+")

	begin
		config.each_line do |line|
			if line =~ /^$/ || line =~ /^\W*\#/
				next
			end

			line = line.chomp

			key, value = line.split('\W+', 2)

			if key == 'hostname'
				@hostname = value
			elsif key == 'port'
				@port = value
			elsif key == 'documentRoot'
				@documentRoot = value
			elsif key == 'indexFiles'
				@indexFiles = value.split(',')
			elsif key == 'mimeFile'
				@mimeFile = value
			elsif key == 'accessLog'
				@accessLog = value
			elsif key == 'errorLog'
				@errorLog = value
			elsif key == 'debugLog'
				@debugLog = value
			elsif key == 'loadMod'
				@loadMod = value.split(',')
			end

		end
	ensure
		config.close
	end	
end

def get(key)
	if key == 'hostname'
		return @hostname
	elsif key == 'port'
		return @port
	elsif key == 'documentRoot'
		return @documentRoot
	elsif key == 'indexFiles'
		return @indexFiles
	elsif key == 'mimeFile'
		return @mimeFile
	elsif key == 'accessLog'
		return @accessLog
	elsif key == 'errorLog'
		return @errorLog
	elsif key == 'debugLog'
		return @debugLog
	elsif key == 'loadMod'
		return @loadMod
	elsif key == 'version'
		return @version
	end
end

end  # end class Config
