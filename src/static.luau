local fs = require("@lune/fs")
local Context = require("./context")
type Context = Context.Context

-- From https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
local mimeTypes = {
	aac = "audio/aac",
	abw = "application/x-abiword",
	apng = "image/apng",
	arc = "application/x-freearc",
	avif = "image/avif",
	avi = "video/x-msvideo",
	azw = "application/vnd.amazon.ebook",
	bin = "application/octet-stream",
	bmp = "image/bmp",
	bz = "application/x-bzip",
	bz2 = "application/x-bzip2",
	cda = "application/x-cdf",
	csh = "application/x-csh",
	css = "text/css",
	csv = "text/csv",
	doc = "application/msword",
	docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
	eot = "application/vnd.ms-fontobject",
	epub = "application/epub+zip",
	gz = "application/gzip",
	gif = "image/gif",
	htm = "text/html",
	html = "text/html",
	ico = "image/vnd.microsoft.icon",
	ics = "text/calendar",
	jar = "application/java-archive",
	jpeg = "image/jpeg",
	jpg = "image/jpeg",
	js = "text/javascript",
	json = "application/json",
	jsonld = "application/ld+json",
	mid = "audio/midi, audio/x-midi",
	midi = "audio/midi, audio/x-midi",
	mjs = "text/javascript",
	mp3 = "audio/mpeg",
	mp4 = "video/mp4",
	mpeg = "video/mpeg",
	mpkg = "application/vnd.apple.installer+xml",
	odp = "application/vnd.oasis.opendocument.presentation",
	ods = "application/vnd.oasis.opendocument.spreadsheet",
	odt = "application/vnd.oasis.opendocument.text",
	oga = "audio/ogg",
	ogv = "video/ogg",
	ogx = "application/ogg",
	opus = "audio/ogg",
	otf = "font/otf",
	png = "image/png",
	pdf = "application/pdf",
	php = "application/x-httpd-php",
	ppt = "application/vnd.ms-powerpoint",
	pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation",
	rar = "application/vnd.rar",
	rtf = "application/rtf",
	sh = "application/x-sh",
	svg = "image/svg+xml",
	tar = "application/x-tar",
	tif = "image/tiff",
	tiff = "image/tiff",
	ts = "video/mp2t",
	ttf = "font/ttf",
	txt = "text/plain",
	vsd = "application/vnd.visio",
	wav = "audio/wav",
	weba = "audio/webm",
	webm = "video/webm",
	webp = "image/webp",
	woff = "font/woff",
	woff2 = "font/woff2",
	xhtml = "application/xhtml+xml",
	xls = "application/vnd.ms-excel",
	xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
	xml = "application/xml",
	xul = "application/vnd.mozilla.xul+xml",
	zip = "application/zip",
	["3gp"] = "video/3gpp",
	["3g2"] = "video/3gpp2",
	["7z"] = "application/x-7z-compressed",
}

local function getMimeType(file: string): string
	local extension = file:match("^.+(%..+)$")
	if extension then
		extension = extension:sub(2):lower() -- Remove the dot and convert to lowercase
		local mimeType = mimeTypes[extension]
		if mimeType and mimeType:find("^text") ~= nil then
			mimeType ..= "; charset=utf-8"
		end
		return mimeType or "application/octet-stream"
	end
	return "application/octet-stream" -- Default MIME type
end

local function static(path: string, directory: string)
	local cleanPath = path:gsub("/$", "")
	return function(c: Context)
		local fullPath = c.req.path
		local relativePath = fullPath:sub(#cleanPath + 1)
		local filePath = directory .. relativePath
		local success, result = pcall(fs.readFile, filePath)

		if not success then
			local indexFilePath = filePath:gsub("/$", "") .. "/index.html"
			local indexSuccess, indexResult = pcall(fs.readFile, indexFilePath)
			if indexSuccess then
				c:header("Content-Type", getMimeType(indexFilePath))
				return c:body(indexResult)
			end
			return c:notFound()
		end

		c:header("Content-Type", getMimeType(filePath))
		return c:body(result)
	end
end

return static
