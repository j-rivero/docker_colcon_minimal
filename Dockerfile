FROM ubuntu:jammy

LABEL maintainer="Jose Luis Rivero <jrivero@openrobotics.org>"
ARG DEBIAN_FRONTEND=noninteractive

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*
# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*
# setup keys
RUN set -eux; \
       key='C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654'; \
       export GNUPGHOME="$(mktemp -d)"; \
       gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
       mkdir -p /usr/share/keyrings; \
       gpg --batch --export "$key" > /usr/share/keyrings/ros2-latest-archive-keyring.gpg; \
       gpgconf --kill all; \
       rm -rf "$GNUPGHOME"
# setup sources.list
RUN echo "deb [ signed-by=/usr/share/keyrings/ros2-latest-archive-keyring.gpg ] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2-latest.list

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV ROS_DISTRO rolling

RUN apt-get update && apt-get install -y \
  build-essential \
  python3-rosdep \
  python3-colcon-common-extensions \
  vim \
  # use to clone repository below 
  git

# Can kill the machine by large memory consumption
# Adjust to your system or disable
RUN echo 'build --jobs=5' >> /etc/bazel.bazelrc
RUN rosdep init

ARG user=buildfarm
ARG group=buildfarm
ARG uid=1000
ARG gid=1000
RUN echo "${user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user}


USER ${uid}:${gid}
WORKDIR /home/buildfarm/ws/src
RUN git clone https://github.com/RobotLocomotion/ros-drake-vendor -b jrivero/initial_code 
WORKDIR /home/buildfarm/ws
RUN date
RUN rosdep update \
  && rosdep install --from-paths . --ignore-src -r -y -i --rosdistro ${ROS_DISTRO}
COPY .entrypoint-colcon.sh ./entrypoint-colcon.sh
ENTRYPOINT [ "./entrypoint-colcon.sh" ]
