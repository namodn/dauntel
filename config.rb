def loadConfig()

	hostname = '0'
	port = '8080'
	documentRoot = 'htdocs'
	indexes = [ 'index.html', 'index.htm' ]
	mimeFile = 'mime.types'

	return [ hostname, port, documentRoot, indexes, mimeFile ]
end

