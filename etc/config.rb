def loadConfig()

	hostname = '0'
	port = '8080'
	documentRoot = 'htdocs'
	indexes = [ 'index.html', 'index.htm' ]
	mimeFile = 'etc/mime.types'
	accessLog = 'log/access.log'
	errorLog = 'log/error.log'
	debugLog = 'log/debug.log'

	return [ hostname, port, documentRoot, indexes, mimeFile, accessLog, errorLog, debugLog ]
end

