#checkov:skip=CKV_DOCKER_2
#checkov:skip=CKV_DOCKER_3
# Using Rocky Linux 8.x as base image to support rpmbuild
FROM rockylinux:8.9

# Copying all contents of rpmbuild repo inside container
# hadolint ignore=DL3045
COPY . .

# Installing tools needed for rpmbuild ,
# depends on BuildRequires field in specfile, (TODO: take as input & install)
# hadolint ignore=DL3041
RUN dnf install -y --allowerasing \
  curl \
  tar \
  rpm-build \
  rpmdevtools \
  gcc \
  make \
  coreutils \
  python39 \
  git \
  && dnf clean all

ENV METLAB_YUM=metlab-yum-1.10.0-27.x86_64.rpm

RUN --mount=type=secret,id=NEXUS_PASSWORD \
    export NEXUS_PASSWORD=$(cat /run/secrets/NEXUS_PASSWORD) \
    && echo -n "length of password: " \
    && echo "${NEXUS_PASSWORD}" | wc -c \
    && curl -k -O \
       https://gst-wx-yum:$NEXUS_PASSWORD@nexus.gst.com/repository/gst-wx/metlab/v1.10/x86_64/$METLAB_YUM \
    && rpm -Uvh "${METLAB_YUM}" \
    && rm "${METLAB_YUM}"

# Setting up node to run our JS file
# Download Node Linux binary
ENV NODE_VER=v20.11.1
ENV NODE_PKG=node-${NODE_VER}-linux-x64.tar.xz
RUN curl -O https://nodejs.org/dist/$NODE_VER/$NODE_PKG \
  && tar --strip-components 1 -xvf $NODE_PKG -C /usr/local \
  && rm $NODE_PKG

# Install dependecies and build main.js
RUN npm install \
&& npm run-script build

# The epel release version might have to get bumped if it's not found
RUN yum -y install epel-release && yum clean all
RUN /bin/sh -c "rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm"
#RUN /bin/sh -c rpm -Uvh \
#    http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm
#RUN rpm -Uvh \
#    http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm

RUN yum install -y \
    sudo \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    cmake \
    bc \
    less \
    indent \
    zlib \
    autoconf \
    bash \
    gzip \
    rpm-build \
    doxygen \
    graphviz-gd \
    unzip \
    docbook-utils \
    swig \
    sed \
    wget \
    postgresql{,-devel} \
    postgresql-libs \
    m4 \
    libgcc \
    libstdc++{,-devel} \
  && yum clean all

#     vim-common \
#     valgrind \
#     strace \
#     lsof \
#     gdb \
#     chkconfig \
#     rsync \
#     telnet \
#

RUN yum install -y \
    perl \
    perl-version \
    perl-IO-Compress-Zlib \
    perl-Date-Manip \
    perl-ExtUtils-Embed \
    perl-devel \
    perl-Glib \
    perl-Gtk2 \
    perl-Gtk2-GladeXML \
    perl-Git \
    perl-Cairo \
    perl-DBI \
  && yum clean all

#    perl-Gtk2-Ex-Simple-OptionMenu \
#    perl-Gtk2-Ex-Simple-CascadeList \

RUN yum install -y \
    gtk-doc \
    netpbm-devel \
    jdk1.8.0_20 \
    glibc \
    glibc-headers \
    libsigc++20 \
    gtk2{,-devel} \
    glib2{,-devel} \
    glibmm24{,-devel} \
    gtkmm24{,-devel} \
    libglade2{,-devel} \
    libglademm24{,-devel} \
    cairo{,-devel} \
    cairomm{,-devel} \
    pangomm{,-devel} \
    gconfmm26{,-devel} \
    libxml2{,-devel} \
    ImageMagick{,-devel} \
    libcurl{,-devel} \
    jasper{,-devel} \
    hdf5{,-devel} \
    gts{,-devel} \
    proj{,-devel} \
    rapidjson{,-devel} \
    shapelib{,-devel} \
    openmotif{,-devel} \
    libjpeg-turbo \
    freetype-devel \
    grib2 \
    bitmap \
    pcre \
    xorg-x11-server-common \
    libXp \
    libX11-common \
    libXrender-devel \
    libXcursor-devel \
    libXinerama-devel \
    libX11-devel \
    libXpm-devel \
    libXi-devel \
  && yum clean all


RUN cat /usr/lib64/pkgconfig/libcurl.pc | grep -v \# > /tmp/libcurl.pc && mv -f /tmp/libcurl.pc /usr/lib64/pkgconfig

# All remaining logic goes inside main.js ,
# where we have access to both tools of this container and
# contents of git repo at /github/workspace
ENTRYPOINT ["node", "/dist/main.js"]
