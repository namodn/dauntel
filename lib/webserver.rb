class WebServer

require 'socket'
require 'lib/webserver.rb'
require 'lib/config.rb'
require 'lib/logger.rb'

#
# Runs on startup
#
def initialize
	cfg = Config.new()

	@debugLog = cfg.get('debugLog')
	@accessLog = cfg.get('accessLog')
	@errorLog = cfg.get('errorLog')
	@documentRoot = cfg.get('documentRoot')
	@indexFiles = cfg.get('indexFiles')
	@mimeFile = cfg.get('mimeFile')
	@version = cfg.get('version')
	@hostname = cfg.get('hostname')
	@port = cfg.get('port')
	@loadMod = cfg.get('loadMod')

	@logger = Logger.new()
end

def start()
	ws = WebServer.new()
	cfg = Config.new()
	logger = Logger.new()
	tcp = TCPServer.new(cfg.get('hostname'), cfg.get('port'))
	
	logger.puts('debug', "started webserver on #{cfg.get('hostname')} port #{cfg.get('port')}")
	
	#
	# This while loop handles incoming HTTP requests from the user agent.
	# The loop is alive as long as we're able to listen..
	#
	
	while (tcp)

		session = tcp.accept

		#
		# grab incoming requests into incoming string
		#
		incoming = session.gets
	
		#
		# Log the whole incoming request
		#
	
		logger.puts('debug', "Request: #{incoming}")
	
		#
		# split incoming by space into request array
		#
	
		request = incoming.split
	
		#
		# define URL
		#
	
		url = request[1]
	
		#
		# security check - don't allow ../ tricks
		#
	
		if ( request[1] =~ /\/\.\./ ) || ( request[1] =~ /\.\.\// )
			ws.serve(url, 'notFound', session)
			session.close
			next
		end
	
		#
		# First part of an HTTP request is always the method,
		# such as GET, PUT, POST, etc.
		#
		method = request[0]
	
		#
		# Second part of an HTTP request is always the URL
		#
		url = request[1]
	
		if method == 'GET'
			#
			# If the getURL method returns something for this URL,
			# then we know how to handle it
			#
			if ws.getURL(url) 
				ws.serve(url, 'ok', session)
			else
			#
			# This isn't an URL that we can handle, return a "file
			# not found" message
			#
				ws.serve(url, 'notFound', session)
			end
		else
			#
			# Only the GET method is supported, anything else
			# is not implemented
			#
				ws.serve(url, 'notImplemented', session)
		end
		session.close
	end
end

#
# header method - this prints out the appropriate HTTP header to the user
# agent
#
def header(errorCode, contentType)
	result = "HTTP/1.1 #{errorCode}\r\n"
#	result += "Date: Sat, 23 Nov 2002 09:03:15 GMT\r\n"
	result += "Server: Dauntel/#{@version} (Unix) Debian/GNU\r\n"
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

		@logger.puts('error', "404 NOT FOUND #{url}, #{ip_addr}")

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
		@logger.puts('error', "501 NOT IMPLEMENTED Returned #{url} from #{ip_addr}")
	#
	#
	# If status is ok, we've got it. Use our reference to the
	# session object to give it to the user.
	#
	elsif status == 'ok'
		setHeader(session, "#{@documentRoot}/#{url}")
		session.print getURL(url)
		@logger.clf(ip_addr,url)

	#
	# If status is unrecognized, log an error and ignore do nothing
	#
	else
		@logger.puts('error', "status is unrecognized : #{status}")
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

	@logger.puts('debug', "mime type for #{filename} is #{mimeType}")
	session.print header('200 OK', mimeType)
end

def getExtention(filename)
	fileElements = filename.split(/\./)
	return fileElements[fileElements.size - 1] 
end

end  # end class WebServer

