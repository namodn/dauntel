#!/usr/bin/ruby -w
#
# dauntel - Web Server written in Ruby
#
# Copyright &copy 2002 Rob Helmer <robert@namodn.com> and 
# Nick Jennings <nkj@namodn.com>, you may accept it under the terms of 
# the GPL ( http://gnu.org/licenses/gpl.txt )
#
# This is just a little program I wrote to start learning Ruby, it comes
# with NO WARRANTY, expressed or implied. 
#
# The performance doesn't seem too bad, but I'd advise against using it
# in a "production" situation :)
#
# It only supports the GET method and text/html files. If you try to GET
# a directory, it must have an index.html or a 404 will be returned.
#
#
# start the server on the defined hostname and port
#

require 'socket'
require 'lib/webserver.rb'
ws = WebServer.new()
tcp = TCPServer.new(ws.config('hostname'), ws.config('port'))

ws.logger("started webserver on #{ws.config('hostname')} port #{ws.config('port')}")

#
# This while loop handles incoming HTTP requests from the user agent.
# The loop is alive as long as we're able to listen..
#
while (session = tcp.accept)
	#
	# grab incoming requests into incoming string
	#
	incoming = session.gets

	#
	# Log the whole incoming request
	#
	ws.logger("Request: #{incoming}")

	#
	# split incoming by space into request array
	#

	request = incoming.split

	#
	# security check - don't allow ../ tricks
	#

	if ( request[1] =~ /\/\.\./ )
		request[1] = '';
	elsif ( request[1] =~ /\.\.\// )
		request[1] = '';
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
			ws.serve(url,session)
		else
		#
		# This isn't an URL that we can handle, return a "file
		# not found" message
		#
			ws.serve('notFound',session)
		end
	else
		#
		# Only the GET method is supported, anything else
		# is not implemented
		#
			ws.serve('notImplemented',session)
	end
	session.close
end
