#!/bin/bash

imageTag=${imageTag:-"nvchecker-email"}

printf -v nvcVersion '%s' "$(docker run -it --rm alpine:latest sh -c "apk update —no-progress --quiet && apk info nvchecker | head -n 1 | cut -d - -f 2 | tr -d '\n'")"
printf -v dateTime '%(%Y-%m-%dT%H:%M:%S%z)T'
printf -v nvcRevision '%s' "$(git ls-remote -t 'https://github.com/lilydjwg/nvchecker.git' "v${nvcVersion}" | cut -f 1)"
printf -v baseDigest '%s' "$(docker image pull alpine:latest | grep -i digest | cut -d ' ' -f 2)"

docker build \
    --tag "${imageTag}" \
    --build-arg baseDigest="${baseDigest}" \
    --build-arg dateTime="${dateTime}" \
    --build-arg nvcRevision="${nvcRevision}" \
    --build-arg nvcVersion="${nvcVersion}" \
    .
