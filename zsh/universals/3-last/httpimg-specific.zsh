# dump rendering of webpage as image!
function httpimg() {
  url=$1
  wkhtmltoimage -q $url - | imgcat

  # TBD windows:
  #   https://www.labnol.org/software/automated-screenshots-of-websites-from-command-line/4786/
  #   IECapt --url=http://www.google.com/ --out=google.png # - stdout?

}
