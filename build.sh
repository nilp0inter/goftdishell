#!/usr/bin/env bash
CGO_ENABLED=1 go build -x -v -a -tags 'netgo osusergo' -ldflags="-linkmode external -extldflags '-static -Wl,-static'" -o goftdishell main.go
