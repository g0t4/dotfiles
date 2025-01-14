local rect = hs.geometry.rect(100, 100, 300, 300)
local webview = hs.webview.newBrowser(rect)
webview:html([[
<html>
<body>
<h1>F U</h1>
</body>
</html>
]])
webview:show()

-- webview:reload()

-- print("webview", hs.inspect(hs.webview))
