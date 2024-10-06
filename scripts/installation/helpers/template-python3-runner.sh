#!/usr/bin/env sh

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/." >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="template"
APP_BASE_NAME=`basename "$0"`
MAINPYPATH=$APP_HOME/template

# Escape application args
save () {
    for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
    echo " "
}
APP_ARGS=`save "$@"`

PYTHONCMD=python3
# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- $TEMPLATE_OPTS "\"$MAINPYPATH\"" "$APP_ARGS"

exec "$PYTHONCMD" "$@"
