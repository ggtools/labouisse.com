#!/usr/bin/env bash

exec bundle exec jekyll serve  --incremental --config _config.yml,_config-localhost.yml --verbose -H 0.0.0.0
