# https://docs.docker.com/engine/getstarted/step_four/#step-4-run-your-new-docker-whale
# WIP
FROM docker/whalesay:latest
RUN apt-get -y update && apt-get install -y fortunes
CMD /usr/games/fortune -a | cowsay