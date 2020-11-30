FROM lambci/lambda:build-go1.x as base
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ENV FIREFOX_URL=http://ftp.mozilla.org/pub/firefox/releases/82.0/linux-x86_64/en-US/firefox-82.0.tar.bz2
ENV GECKODRIVER_VERSION=0.28.0
ENV GECKODRIVER_URL=https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz

# Next, we install Firefox into our Lambda container.
# Amazon Linux's default repositories don't have GTK3 or any of its dependencies.
# We use both CentOS and various Fedora repositories to fill in the blanks.
# This took A LONG TIME to figure out since mostly everyone seems to default
# to running Chromium on Lambda and driving it with Puppeteer and I prefer to not
# contribute to the Chromification of the web.
# Some of this taken from: https://github.com/puppeteer/puppeteer/issues/765
RUN yum -y install pango cairo-gobject libXinerama libXrandr dbus-glib wget libXcursor
RUN \
  rpm -ivh --nodeps --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/atk-2.28.1-2.el7.x86_64.rpm && \
  rpm -ivh --nodeps --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/at-spi2-atk-2.26.2-1.el7.x86_64.rpm && \
  rpm -ivh --nodeps --replacepkgs http://mirror.centos.org/centos/7/os/x86_64/Packages/at-spi2-core-2.28.0-1.el7.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/g/GConf2-3.2.6-7.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/l/libXScrnSaver-1.2.2-6.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/l/libxkbcommon-0.3.1-1.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/l/libwayland-client-1.2.0-3.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/l/libwayland-cursor-1.2.0-3.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/g/gtk3-3.10.4-1.fc20.x86_64.rpm && \
  rpm -ivh --nodeps http://dl.fedoraproject.org/pub/archive/fedora/linux/releases/16/Fedora/x86_64/os/Packages/gdk-pixbuf2-2.24.0-1.fc16.x86_64.rpm && \
  rpm -Uvh --nodeps https://dl.fedoraproject.org/pub/archive/fedora/linux/releases/20/Fedora/x86_64/os/Packages/g/glib2-2.38.2-2.fc20.x86_64.rpm

# Next, we install Brotli.
# Brotli is used to compress Firefox and its dependencies into a file
# small enough to fit into an AWS Lambda layer.
# (Regular compression yields 86MB; we need <250MB across all layers.)
FROM base as brotli
RUN cd /tmp && \
    git clone https://github.com/google/brotli.git && \
    cd brotli && \
    ./bootstrap && \
    ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
      --libexecdir=/usr/lib64/brotli --libdir=/usr/lib64/brotli \
      --datarootdir=/usr/share --mandir=/usr/share/man/man1 --docdir=/usr/share/doc && \
    make && \
    make install

# Next, we install Firefox and Geckodriver.
FROM brotli as geckodriver
RUN cd /tmp && \
    wget -O firefox.tar.bz2 $FIREFOX_URL &&  \
    wget -O geckodriver.tar.gz $GECKODRIVER_URL && \ 
    tar -xf firefox.tar.bz2 && tar -xf geckodriver.tar.gz && \
    mv geckodriver /usr/local/bin && \
    ln -s $PWD/firefox/firefox /usr/local/bin/firefox

# Next, we'll compile a list of files installed today so that we can generate
# a manifest of files to add to our package.
RUN rpm -qa --last | \
      grep "$( date +"%a %d %b %Y")" | \
      cut -f1 -d ' ' | \
      xargs rpm -ql > /rpm.manifest

# Now we remove stuff that isn't needed to reduce our layer size.
RUN rm -r /usr/share/{doc,locale,man,bash-completion}

# Lastly, we do the thing.
FROM geckodriver as app
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
