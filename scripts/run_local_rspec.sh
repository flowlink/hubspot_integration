#!/bin/bash
docker-compose -f docker-compose.yml \
               -f docker-compose.dev.yml \
               run --rm -e RAILS_ENV=test shipstation-integration \
               sh -c "bundle exec rspec ${@}"
