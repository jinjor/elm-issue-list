FROM node:8.9.1
MAINTAINER Yosuke Torii jinjorweb@gmail.com

RUN useradd --user-group --create-home --shell /bin/false app &&\
    yarn global add elm &&\
    yarn global add elm-test &&\
    yarn global add elm-live

ENV HOME=/home/app

USER app

WORKDIR $HOME

COPY package.json elm-package.json /home/app/

RUN yarn install &&\
    elm-package install -y

ENTRYPOINT ["yarn"]
