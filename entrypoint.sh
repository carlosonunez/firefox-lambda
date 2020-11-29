#!/usr/bin/env sh
NOBROTLI="${NOBROTLI:-false}"

# Build firefox.zip
cd /tmp

>&2 echo "INFO: Building firefox.zip."
zip -r firefox.zip /tmp/firefox /usr/local/bin/geckodriver $(cat /rpm.manifest)

# Build firefox.br
if test "$NOBROTLI" != "true"
then
  >&2 echo "INFO: Building firefox.br. This can take up to 20 minutes."
  tar -cf firefox.tar -- /tmp/firefox $(find /tmp/firefox/*.so | \
    xargs ldd | \
    grep '=>' | \
    grep -v not | \
    sed 's/.*=> \(.*\) (.*$/\1/' | tr '\n' ' ')
  brotli -jvZ firefox.tar
fi

# Finished!
>&2 echo "INFO: Finished. Now run 'docker cp $(hostname):/tmp/firefox.* .' to get these files."
