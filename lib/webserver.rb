class WebServer

#
# config method, define all configurable settings
#
def initialize
        require 'config.rb'
	@version = '0.2'
	@hostname, @port, @documentRoot, @indexes = loadConfig()
end

def config(key)
	if key == 'hostname'
		return @hostname
	elsif key == 'port'
		return @port
	elsif key == 'documentRoot'
		return @documentRoot
	elsif key == 'indexes'
		return @indexes
	end
end

#
# header method - this prints out the appropriate HTTP header to the user
# agent
#
def header(errorCode, contentType)
	result = "HTTP/1.1 #{errorCode}\r\nContent-type: #{contentType}\r\n\r\n"
	return result
end

#
# logger method - this handles logging incoming HTTP requests
#
def logger(log)
	puts "#{log}"
end

#
# getURL method - this handles incoming GET requests
#
def getURL(url)
	if fileReader(url)
		result = fileReader(url)
		return result
	end
end

#
# fileReader method - this handles reading file contents
#
def fileReader(filename)
	#
	# put the documentRoot and the filename together
	#
	fullFilename = "#{config('documentRoot')}#{filename}"

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

			@indexes.each do |fileEntry|

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
	return result
end

#
# serve method - this handles interaction with the user agent
#
def serve(url, status, session)

	#
	# If the word "notFound" was passed, we don't have it
	#
	if status == 'notFound'
		session.print header('HTTP 1.1 404/NOT FOUND','text/html')

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
		session.print header('HTTP 1.1 501/NOT IMPLEMENTED','text/html')
		session.print 'Sorry, that method is not implemented on this server.'
	#
	#
	# If status is ok, we've got it. Use our reference to the
	# session object to give it to the user.
	#
	elsif status == 'ok'
		session.print header('HTTP 1.1 500/OK','text/html')
		session.print getURL(url)
		logger("Returned #{url}")

	#
	# If status is unrecognized, log an error and ignore do nothing
	#
	else
		logger("status is unrecognized : #{status}")
	end

end


end  # end class WebServer

