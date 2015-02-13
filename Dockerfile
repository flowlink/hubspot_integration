FROM rlister/ruby:2.1.5
MAINTAINER Ric Lister, ric@spreecommerce.com

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq \
    build-essential zlib1g-dev libreadline6-dev libyaml-dev libssl-dev \
    locales \
    git

## set the locale so gems built for utf8
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /app

## help docker cache bundle
ADD ./Gemfile /app/
ADD ./Gemfile.lock /app/
RUN bundle install --without development test

ADD ./ /app

EXPOSE 5000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "unicorn", "-p", "5000", "-c", "config/unicorn.rb" ]
