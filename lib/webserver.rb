class WebServer

#
# config method, define all configurable settings
#
def initialize
	configFile = 'etc/dauntel.cfg'
	@version = '0.2'
	loadConfig(configFile)
end

def loadConfig(configFile)
	@hostname, @port, @documentRoot, @indexFiles, @mimeFile, 
	@accessLog, @errorLog, @debugLog, @loadMod = 
	'0', '8080', 'htdocs/', ['index.html', 'index.htm'], 'etc/mime.types', 
	'log/access.log', 'log/error.log', 'log/debug.log', []

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

def config(key)
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
	end
end

#
# header method - this prints out the appropriate HTTP header to the user
# agent
#
def header(errorCode, contentType)
	result = "HTTP/1.1 #{errorCode}\r\n"
#	result += "Date: Sat, 23 Nov 2002 09:03:15 GMT\r\n"
	result += "Server: Dauntel/0.3 (Unix) Debian/GNU\r\n"
#	result += "Last-Modified: Tue, 30 Apr 2002 02:11:15 GMT\r\n"
#	result += "ETag: c02f-13be-3ccdfd4\r\n"
#	result += "Accept-Ranges: bytes\r\n"
#	result += "Content-Length: 5054\r\n"
	result += "Keep-Alive: timeout=15, max=100\r\n"
	result += "Connection: Keep-Alive\r\n"
	result += "Content-type: #{contentType}; charset=iso-8859-1\r\n"
	result += "\r\n"
	return result
end

#
# logger method - this handles logging incoming HTTP requests
#
def logger(severity, log)
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
# getURL method - this handles incoming GET requests
#
def getURL(url)
	return fileReader(url)
end

#
# fileReader method - this handles reading file contents
#
def fileReader(filename)
	#
	# put the documentRoot and the filename together
	#
	fullFilename = "#{@documentRoot}#{filename}"

	begin
		#
		# what type of file is this?
		#
		fileType = File.ftype(fullFilename)

		#
		# if it's a file, open it!
		#
		if fileType == 'file'
			file = open(fullFilename, "r+")

		#
		# if it's a directory, look for index.html
		#
		elsif fileType == 'directory'

			foundIndex = ''

			@indexFiles.each do |fileEntry|

				if (File.exists?"#{fullFilename}/#{fileEntry}")
					foundIndex = fileEntry
					break
				end

			end 

			begin
				file = open("#{fullFilename}/#{foundIndex}", "r+")

			#
			# Error handling.. if indexes weren't found, just
			# return nothing
			#
			rescue
				return
			end
		end

	#
	# If no valid files were found, return nothing
	#
	rescue
		return
	end

	#
	# If we got this far, we must have a valid file.
	# Read all lines and return them.
	#
	result = file.readlines
	file.close
	return result
end

#
# serve method - this handles interaction with the user agent
#
def serve(url, status, session)

	addr = session.peeraddr
	ip_addr = addr[3]

	#
	# If the word "notFound" was passed, we don't have it
	#
	if status == 'notFound'
		session.print header('404 NOT FOUND','text/html')

		logger('error', "404 NOT FOUND #{url}, #{ip_addr}")

		if File.exists?"#{@documentRoot}/missing.html" 
			session.print getURL("/missing.html")
		else
			session.print '<html><head><title>404 Not Found</title>'
			session.print '</head><body><h1>Not Found!</h1>'
			session.print "<p>The URL #{url} was not found on this server.</p>"
			session.print "<hr /><address>dante http server v#{@version} - #{@hostname} #{@port}</address></body></html>"
		end

	#
	# If the word "notImplemented" was passed, we can't do it
	#
	elsif status == 'notImplemented'
		session.print header('501 NOT IMPLEMENTED','text/html')
		session.print 'Sorry, that method is not implemented on this server.'
		logger('error', "501 NOT IMPLEMENTED Returned #{url} from #{ip_addr}")
	#
	#
	# If status is ok, we've got it. Use our reference to the
	# session object to give it to the user.
	#
	elsif status == 'ok'
		setHeader(session, "#{@documentRoot}/#{url}")
		session.print getURL(url)
		logger('access', "200 OK #{url} from #{ip_addr}")

	#
	# If status is unrecognized, log an error and ignore do nothing
	#
	else
		logger('error', "status is unrecognized : #{status}")
	end

end

#
# Prints the header for the file based on it's mime type
#
def setHeader(session, filename)
	mimeType = "text/html"
	fileExt = getExtention(filename)

	file = open(@mimeFile, "r+")

	begin

		file.each_line do |line|
			if line =~ /^$/
				next
			elsif line =~ /^\W*\#/
				next
			end

			lineArray = line.split
			type = lineArray.shift

			lineArray.each do |entry|
				if fileExt == entry
					mimeType = type
					break
				end
			end

		end
	
	ensure
		file.close
	end

	logger('debug', "mime type for #{filename} is #{mimeType}")
	session.print header('200 OK', mimeType)
end

def getExtention(filename)
	fileElements = filename.split(/\./)
	return fileElements[fileElements.size - 1] 
end

end  # end class WebServer

