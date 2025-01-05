# open-with / duti

##

- `duti`
  - https://github.com/moretension/duti/
  - https://www.chainsawonatireswing.com/2012/09/19/changing-default-applications-on-a-mac-using-the-command-line-then-a-shell-script/


## Glossary

- **`UTI`** - Apple's `Universal Type Identifier`
- `URL scheme` - 
  - List of [URI schemes](https://en.wikipedia.org/wiki/List_of_URI_schemes)


`duti` sets `default handlers` `applications` for `UTI`s, `URL schems`, `filename extensions` and `MIME types`

### 1. `UTI`

- `UTI` is short for Apple's `Uniform Type Identifiers`


### 2. `URL schemes`

### 3. `filename extensions`

### 4. `MIME types`



## TODO PORT HELP FROM yml comments:


# - Run this to find the id of an app
#    - duti -x md # where md is the extension you care about, last value returned is the app bundle id
#    - if no default app then use 
#      - osascript -e "id of app "Sublime Text 2"" # to get app bundle id
# Commands:
#   man duti                     # best offline help I can find for duti
#   duti -h

## TWO WAYS TO SET HANDLERS
# 1. SETTINGS FILE
#   duti [ settings_path ]
#   - app_id = bundle ID (handler app)
#
#   2 settings file line: 
#    app_id    UTI    role
#    com.apple.Safari    public.html    all
#
#    app_id    url_scheme
#    org.mozilla.Firefox     ftp
#
#   .plist file format
#   - "DUTISettings" key
#
#   valid roles: 
#   - all 
#   - viewer (reading / displaying)
#   - editor (manipulate / save)
#   - shell (execute)
#   - none (just to provide icon, not to open)
# 
# 2. CLI ARGS
#   duti -s # -s tells duti to read arguments from the CLI
#   - 2 args: handler for URL
#     - duti -s HANDLER URL
#   - 3 args: handler for extension, UTI or MIME type (dictated by 2nd argument)
#     - NO dots or STARTS WITH DOT = extension 
#     - CONTAINS SLASH = MIME type
#     - OTHERWISE (DOT NOT A START) = UTI


#   duti -d ext                  # display association
#   duti -x ext 

