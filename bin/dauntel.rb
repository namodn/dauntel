#!/usr/bin/ruby -w
#
# dauntel - Web Server written in Ruby
#
# Copyright &copy 2002 Rob Helmer <robert@namodn.com> and 
# Nick Jennings <nkj@namodn.com>, you may accept it under the terms of 
# the GPL ( http://gnu.org/licenses/gpl.txt )
#
# dauntel comes with NO WARRANTY, expressed or implied. 
#
# The performance doesn't seem too bad, but I'd advise against using it
# in a "production" situation :)
#
# It only supports the GET method and text/html files. If you try to GET
# a directory, it must have an index.html or a 404 will be returned.
#

#
# start the server on the defined hostname and port in the dauntel.cfg
#

require 'lib/webserver.rb'

ws = WebServer.new()
ws.start()

