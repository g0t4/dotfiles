--
-- TODO try this with obs websocket code
-- https://25thandclement.com/~william/projects/cqueues.html
local cqueues = require("cqueues")
local socket = require("cqueues.socket")

local con = socket.connect("www.google.com", 443)
con:starttls()

local inner = cqueues.new()
local outer = cqueues.new()

inner:wrap(function()
	con:write("GET / HTTP/1.0\n")
	con:write("Host: www.google.com:443\n\n")

	for ln in con:lines() do
		print(ln)
	end
end)

outer:wrap(function()
	assert(inner:loop())
end)

assert(outer:loop())

