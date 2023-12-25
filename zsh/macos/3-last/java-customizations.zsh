ealias j='java'
ealias jv='java -version'

ealias exJH='export JAVA_HOME=$(/usr/libexec/java_home --version 17)'
ealias exJV='export JAVA_VERSION=17'

# list all JVMs
ealias jh='/usr/libexec/java_home --verbose' # returns highest version by default (not sure how it works with more than one distribution vendor ie temurin vs openjdk vs microsoft-openjdk)
ealias jhv='/usr/libexec/java_home --verbose --version' # 17/11/etc
