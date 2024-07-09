import os
import re
import sys
import psutil
import json

alfred_query = sys.argv[1] if len(sys.argv) > 1 else ''

items = []
for proc in psutil.process_iter():
    processName = proc.name()
    pid = proc.pid
    subtitle = str(pid)
    try:
        # todo can i check for permission to access cmd_line first, so don't need to catch exceptions when accessing a proc I don't have permission to access
        cmd_line = proc.cmdline()
        if len(cmd_line) > 0:
            subtitle += " - " + " ".join(cmd_line)
    except:
        cmd_line = []
        pass
    if alfred_query != '' and alfred_query.lower() not in processName.lower():
        # TODO match on cmd_line as well (either or)
        continue
    icon_path = processName

    # extract /path/to/foo.app from /path/to/foo.app/foo/bar/bam.app/do/be/doo, ONLY match top level /path/to/foo.app not nested ones, IOTW don't be greedy with longest match, use shortest match
    app_regex = r'(.+?\.app)(/|$)'
    app_match = re.match(app_regex, cmd_line[0] if len(cmd_line) > 0 else processName)
    if app_match:
        icon_path = app_match.group(1)

    process_item = {
        "uid": str(pid),
        "title": processName,
        "subtitle": subtitle,
        "arg": str(pid),
        "autocomplete": processName,
        "icon": {
            "type": "fileicon",
            "path": icon_path
        }
    }
    items.append(process_item)

print(json.dumps({"items": items}))

## JSON or XML
# JSON REF: https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
#
## *** REFERENCE:
# cat << EOB
# {"items": [

# 	{
# 		"uid": "desktop",
# 		"type": "file",
# 		"title": "Desktop",
# 		"subtitle": "~/Desktop",
# 		"arg": "~/Desktop",
# 		"autocomplete": "Desktop",
# 		"icon": {
# 			"type": "fileicon",
# 			"path": "~/Desktop"
# 		}
# 	},

# 	{
# 		"valid": false,
# 		"uid": "flickr",
# 		"title": "Flickr",
# 		"icon": {
# 			"path": "flickr.png"
# 		}
# 	},

# 	{
# 		"uid": "image",
# 		"type": "file",
# 		"title": "My holiday photo",
# 		"subtitle": "~/Pictures/My holiday photo.jpg",
# 		"autocomplete": "My holiday photo",
# 		"icon": {
# 			"type": "filetype",
# 			"path": "public.jpeg"
# 		}
# 	},

# 	{
# 		"valid": false,
# 		"uid": "alfredapp",
# 		"title": "Alfred Website",
# 		"subtitle": "https://www.alfredapp.com/",
# 		"arg": "alfredapp.com",
# 		"autocomplete": "Alfred Website",
# 		"quicklookurl": "https://www.alfredapp.com/",
# 		"mods": {
# 			"alt": {
# 				"valid": true,
# 				"arg": "alfredapp.com/powerpack",
# 				"subtitle": "https://www.alfredapp.com/powerpack/"
# 			},
# 			"cmd": {
# 				"valid": true,
# 				"arg": "alfredapp.com/powerpack/buy/",
# 				"subtitle": "https://www.alfredapp.com/powerpack/buy/"
# 			},
# 		},
# 		"text": {
# 			"copy": "https://www.alfredapp.com/ (text here to copy)",
# 			"largetype": "https://www.alfredapp.com/ (text here for large type)"
# 		}
# 	}

# ]}
# EOB
