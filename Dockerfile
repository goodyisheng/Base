FROM ubuntu:focal-20211006

USER root
#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://mirrors.ustc.edu.cn/ubuntu focal main universe\n" > /etc/apt/sources.list \
  && echo "deb http://mirrors.ustc.edu.cn/ubuntu focal-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.ustc.edu.cn/ubuntu focal-security main universe\n" >> /etc/apt/sources.list
# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    openjdk-11-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    curl \
    supervisor \
    gnupg2 \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-11-openjdk-amd64/conf/security/java.security

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata


#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
COPY selenium-server-4.1.0.jar /opt/selenium/selenium-server.jar
COPY config.toml /opt/selenium/config.toml

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#==============
# Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install \
  xvfb \
  pulseaudio \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==============================
# Locale and encoding settings
#==============================
ENV LANG_WHICH en
ENV LANG_WHERE US
ENV ENCODING UTF-8
ENV LANGUAGE ${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
ENV LANG ${LANGUAGE}
# Layer size: small: ~9 MB
# Layer size: small: ~9 MB MB (with --no-install-recommends)
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
  language-pack-en \
  tzdata \
  locales \
  && locale-gen ${LANGUAGE} \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get -qyy autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

#=====
# VNC
#=====
# RUN apt-get update -qqy \
#   && apt-get -qqy install \
#   x11vnc \
#   && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy install \
  fluxbox \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#================
# Font libraries
#================
# libfontconfig            ~1 MB
# libfreetype6             ~1 MB
# xfonts-cyrillic          ~2 MB
# xfonts-scalable          ~2 MB
# fonts-liberation         ~3 MB
# fonts-ipafont-gothic     ~13 MB
# fonts-wqy-zenhei         ~17 MB
# fonts-tlwg-loma-otf      ~300 KB
# ttf-ubuntu-font-family   ~5 MB
#   Ubuntu Font Family, sans-serif typeface hinted for clarity
# Removed packages:
# xfonts-100dpi            ~6 MB
# xfonts-75dpi             ~6 MB
# Regarding fonts-liberation see:
#  https://github.com/SeleniumHQ/docker-selenium/issues/383#issuecomment-278367069
# Layer size: small: 36.28 MB (with --no-install-recommends)
# Layer size: small: 36.28 MB
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
  libfontconfig \
  libfreetype6 \
  xfonts-cyrillic \
  xfonts-scalable \
  fonts-liberation \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei \
  fonts-tlwg-loma-otf \
  ttf-ubuntu-font-family \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

########################################
# noVNC exposes VNC through a web page #
########################################
# Download https://github.com/novnc/noVNC dated 2021-03-30 commit 84f102d6a9ffaf3972693d59bad5c6fddb6d7fb0
# Download https://github.com/novnc/websockify dated 2021-03-22 commit c5d365dd1dbfee89881f1c1c02a2ac64838d645f
# COPY noVNC-84f102d6a9ffaf3972693d59bad5c6fddb6d7fb0.zip noVNC.zip
# COPY websockify-c5d365dd1dbfee89881f1c1c02a2ac64838d645f.zip websockify.zip
# ENV NOVNC_SHA="84f102d6a9ffaf3972693d59bad5c6fddb6d7fb0" \
#   WEBSOCKIFY_SHA="c5d365dd1dbfee89881f1c1c02a2ac64838d645f"

# RUN unzip -x noVNC.zip \
#   && mv noVNC-${NOVNC_SHA} /opt/bin/noVNC \
#   && cp /opt/bin/noVNC/vnc.html /opt/bin/noVNC/index.html \
#   && rm noVNC.zip \
#   && unzip -x websockify.zip \
#   && rm websockify.zip \
#   && rm -rf websockify-${WEBSOCKIFY_SHA}/tests \
#   && mv websockify-${WEBSOCKIFY_SHA} /opt/bin/noVNC/utils/websockify

#=========================================================================================================================================
# Run this command for executable file permissions for /dev/shm when this is a "child" container running in Docker Desktop and WSL2 distro
#=========================================================================================================================================
RUN chmod +x /dev/shm


#==============================
# Scripts to run Selenium Node and XVFB
#==============================
# COPY start-xvfb.sh \
#   /opt/bin/

#==============================
# Supervisor configuration file
#==============================
# COPY selenium.conf /etc/supervisor/conf.d/

#==============================
# Generating the VNC password as seluser
# So the service can be started with seluser
#==============================

# RUN mkdir -p ${HOME}/.vnc \
#   && x11vnc -storepasswd secret ${HOME}/.vnc/passwd

#==========
# Relaxing permissions for OpenShift and other non-sudo environments
#==========
# RUN sudo chmod -R 777 ${HOME} \
#   && sudo chgrp -R 0 ${HOME} \
#   && sudo chmod -R g=u ${HOME}

#==============================
# Scripts to run fluxbox, x11vnc and noVNC
#==============================
# COPY start-vnc.sh \
#   start-novnc.sh \
#   /opt/bin/

#==============================
# Selenium Grid logo as wallpaper for Fluxbox
#==============================
COPY selenium_grid_logo.png /usr/share/images/fluxbox/ubuntu-light.png

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV SCREEN_DPI 96
ENV DISPLAY :99.0
ENV DISPLAY_NUM 99
ENV START_XVFB true
ENV START_NO_VNC true
# Path to the Configfile
ENV CONFIG_FILE=/opt/selenium/config.toml
ENV GENERATE_CONFIG true

#========================
# Selenium Configuration
#========================
# As integer, maps to "max-concurrent-sessions"
ENV SE_NODE_MAX_SESSIONS 1
# As integer, maps to "session-timeout" in seconds
ENV SE_NODE_SESSION_TIMEOUT 300
# As boolean, maps to "override-max-sessions"
ENV SE_NODE_OVERRIDE_MAX_SESSIONS false

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Creating base directory for Xvfb
# RUN  sudo mkdir -p /tmp/.X11-unix && sudo chmod 1777 /tmp/.X11-unix

# Copying configuration script generator
# COPY generate_config /opt/bin/generate_config

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
COPY google-chrome-stable_current_amd64.deb /tmp/google-chrome-stable_current_amd64.deb

RUN apt-get update -qqy \
  && apt-get -qqy install \
  /tmp/google-chrome-stable_current_amd64.deb \
  && apt-get install -f \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary

RUN chmod 755 /opt/bin/wrap_chrome_binary \
  && /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
COPY chromedriver_linux64.zip /tmp/chromedriver_linux64.zip
RUN rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-96.0.4664.45 \
  && chmod 755 /opt/selenium/chromedriver-96.0.4664.45 \
  && rm /tmp/chromedriver_linux64.zip \
  && sudo ln -fs /opt/selenium/chromedriver-96.0.4664.45 /usr/bin/chromedriver


#============================================
# Dumping Browser name and version for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name

#====================================
# Scripts to run Selenium Standalone
#====================================

# COPY start-selenium-standalone.sh /opt/bin/start-selenium-standalone.sh

# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true

EXPOSE 4444

EXPOSE 5900

CMD ["java","-jar","/opt/selenium/selenium-server.jar","standalone","--config","/opt/selenium/config.toml"]
