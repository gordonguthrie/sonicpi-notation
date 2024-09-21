FROM elixir:1.17.1

USER root

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y make
RUN apt-get install -y unzip
RUN apt-get install -y lynx
RUN apt-get install -y emacs
RUN apt-get install -y wget
RUN apt-get install -y sudo
RUN apt-get install -y lsof
RUN apt-get install -y net-tools
RUN apt-get install -y x11-apps
RUN apt-get install -y nodejs
RUN apt-get install -y npm

# install Jekyll to test documentation
RUN apt-get install -y ruby-full build-essential zlib1g-dev
RUN gem install jekyll bundler
COPY _literate/Gemfile /tmp
RUN bundle install --gemfile /tmp/Gemfile

# Replace 1000 with your user / group id
RUN export uid=501 gid=20 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer && \
    mkdir /home/developer/.mix && \
    chown ${uid}:${gid} -R /home/developer/.mix && \
	  mix local.hex --force && \
	  mix archive.install hex phx_new 1.7.14 --force

USER developer

#CMD ["/bin/bash"]
CMD tail -f /dev/null
