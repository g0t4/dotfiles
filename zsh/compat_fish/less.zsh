export LESS="-I -F -R $LESS" 
# -I triggers case insensitive searching in less
# -F quit if less than one page of output
# -R raw control characters => ie ascii color codes (ie ESC[33m)
export PAGER="less"

export WATCH_INTERVAL=0.5  # default to half second so I dont have to pass watch -n0.5!!!! # confirm by run watch cmd and see upper left what interval is
#  see `man watch`