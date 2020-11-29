#!/usr/bin/env sh

# Build firefox.zip
cd /tmp

>&2 echo "INFO: Building firefox.zip."
zip -r firefox.zip /tmp/firefox $(find /tmp/firefox/*.so | \
  xargs ldd | \
  grep '=>' | \
  grep -v not | \
  sed 's/.*=> \(.*\) (.*$/\1/' | \
  tr '\n' ' ')

# Build firefox.br
>&2 echo "INFO: Building firefox.br. This can take up to 20 minutes."
tar -cf firefox.tar -- /tmp/firefox $(find /tmp/firefox/*.so | \
  xargs ldd | \
  grep '=>' | \
  grep -v not | \
  sed 's/.*=> \(.*\) (.*$/\1/' | tr '\n' ' ')
brotli -jvZ firefox.tar

# Finished!
>&2 echo "INFO: Finished. Now run 'docker cp $(hostname):/tmp/firefox.* .' to get these files."
