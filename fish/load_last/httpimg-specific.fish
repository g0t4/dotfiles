# dump rendering of webpage as image!
function httpimg
    set url $argv[1]
    wkhtmltoimage -q $url - | imgcat
end
