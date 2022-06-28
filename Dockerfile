FROM ruby:2.7-alpine
LABEL maintainer="NuRelm <development@nurelm.com>"

RUN apk add --no-cache --update build-base libcurl linux-headers git shared-mime-info tzdata

WORKDIR /app
COPY ./ /app

RUN bundle install --jobs 5

ARG DEVELOPMENT
RUN if [ -z $DEVELOPMENT ] ; then apk del build-base linux-headers ; fi

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "foreman", "start" ]
