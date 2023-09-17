FROM ubuntu:23.04

ARG ARG_TIMEZONE=Asia/Tokyo

ENV ENV_TIMEZONE ${ARG_TIMEZONE}
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

# install supervisor, cron, ffmpeg, generate locale and set time &&
# create directory for child images to store configuration
# and create file for cron log
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
  locales \
  tzdata \
  ntp \
  ntpstat \
  ntpdate \
  supervisor=4.2.5 \
  cron \
  python3 \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8 \
  && echo "$ENV_TIMEZONE" > /etc/timezone \
  && ln -fsn /usr/share/zoneinfo/$ENV_TIMEZONE /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata

# copy supervisor base configuration and child tasks
COPY supervisor.conf /etc/supervisor/supervisord.conf
COPY supervisor/* /etc/supervisor/conf.d/

# copy other necessary resources/scripts
COPY hello_world.py /root/

# copy cron tasks, change rights and apply
COPY cron/* /etc/cron.d/
RUN chmod 0600 /etc/cron.d/test
RUN crontab /etc/cron.d/test

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# make supervisor http server available
EXPOSE 9001

# default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
