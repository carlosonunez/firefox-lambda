# firefox-lambda

Looking to use Lambda in Firefox? Download `firefox.zip` into your layer and decompress.

Want to use a different version of Firefox? Run `build_firefox.sh` in a Docker container
running the [`lambci/lambda`](https://github.com/lambci/docker-lambda/) image to regenerate
`firefox.zip` and `firefox.br` (takes ~15 minutes), then copy those files from the container
into your layer.

This is provided as-is.
