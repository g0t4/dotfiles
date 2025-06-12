-- before plugin loader
require("early")

require("bootstrap-lazy")

-- after plugin loader (but not guaranteed to be after specific plugins)
require('non-plugins.werkspaces.werkspace')
