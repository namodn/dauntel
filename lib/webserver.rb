#
# config method, define all configurable settings
#
def config(key)
	if key == 'hostname'
		return 'namodn.com'
	elsif key == 'port'
		return '8080'
	elsif key == 'documentRoot'
		return '/home/robert/src/rrw/htdocs'
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
			begin
				file = open("#{fullFilename}/index.html", "r+")

			#
			# Error handling.. if index.html wasn't found, just
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
def serve(url,session)
	#
	# If the word "notFound" was passed, we don't have it
	#
	if url == 'notFound'
		session.print header('HTTP 1.1 404/NOT FOUND','text/html')
		session.print 'Sorry, that file was not found on this server.'

	#
	# If the word "notImplemented" was passed, we can't do it
	#
	elsif url == 'notImplemented'
		session.print header('HTTP 1.1 501/NOT IMPLEMENTED','text/html')
		session.print 'Sorry, that method is not implemented on this server.'
	#
	#
	# If url is anything else, we've got it. Use our reference to the
	# session object to give it to the user.
	#
	else
		session.print header('HTTP 1.1 500/OK','text/html')
		session.print getURL(url)
	end
	logger("Returned #{url}")
end
