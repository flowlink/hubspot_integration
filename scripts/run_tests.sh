#!/bin/bash
docker-compose run --rm -e RAILS_ENV=test web \
               sh -c "bundle exec rspec ${@}"
