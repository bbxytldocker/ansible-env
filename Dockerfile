FROM centos:6.8
MAINTAINER bbxytl <bbxytl@gmail.com>

# User config
ENV UID="1000" \
	UNAME="ansible" \
	GID="1000" \
	GNAME="ansible" \
	SHELL="/bin/bash" \
	UHOME="/home/ansible"

# User
RUN yum -y install sudo \
# Create HOME dir
	&& mkdir -p "${UHOME}" \
	&& chown "${UID}":"${GID}" "${UHOME}" \
# Create user
	&& echo "${UNAME}:x:${UID}:${GID}:${UNAME},,,:${UHOME}:${SHELL}" \
	>> /etc/passwd \
	&& echo "${UNAME}::17032:0:99999:7:::" \
	>> /etc/shadow \
# No password sudo
	&& echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" \
	> "/etc/sudoers.d/${UNAME}" \
	&& chmod 0440 "/etc/sudoers.d/${UNAME}" \
# Create group
	&& echo "${GNAME}:x:${GID}:${UNAME}" \
	>> /etc/group

# Install Soft Base
RUN yum -y install \
	epel-release \
	wget  \
# Cleanup
	&& rm -rf \
	/tmp/*  \
	/var/cache/* \
	/var/log/* \
	/var/tmp/* \
	&& mkdir /var/cache/yum
# RUN wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo

# Install ansible
RUN yum groupinstall -y "Development tools" \
	&& yum install -y \
		tar git bash tmux vim \
		ansible \
		python \
		zlib-devel \
		bzip2-devel \
		ncurses-devel \
		sqlite-devel \
		openssl-devel openssh-server openssh-client \
		libselinux-python \
		rsync tree lrzsz net-tools nmap \
		gcc gdb \
		iptraf iotop sysstat \
		bc ntp ntpdate \
# Cleanup
	&& rm -rf \
	/tmp/*  \
	/var/cache/* \
	/var/log/* \
	/var/tmp/* \
	&& mkdir /var/cache/yum

# COPY ./download/Python-2.17.14.tgz  /tmp/
RUN cd /tmp/ \
	&& wget https://www.python.org/ftp/python/2.7.14/Python-2.7.14.tgz \
	&& wget https://bootstrap.pypa.io/ez_setup.py \
	&& tar zxf Python-2.7.14.tgz \
	&& cd Python-2.7.14 \
	&& ./configure \
	&& make && make install  \
	&& cd /tmp/ \
	&& python2.7 ez_setup.py \
	&& easy_install-2.7 pip \
	&& pip2.7 install virtualenv \
# Cleanup
	&& rm -rf \
	/tmp/*  \
	/var/cache/* \
	/var/log/* \
	/var/tmp/* \
	&& mkdir /var/cache/yum

RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN /bin/echo 'root:123456'|chpasswd
EXPOSE 22

USER $UNAME
RUN mkdir -p $UHOME/shell/env \
	&& cd $UHOME/shell/env \
	&& virtualenv ansible

COPY ./bash-config/bashrc $UHOME/.bashrc
COPY ./bash-config/tmux.conf $UHOME/.tmux.conf

RUN mkdir -p $UHOME/.ssh  \
	&& chmod 700 $UHOME/.ssh \
	&& cd $UHOME/.ssh \
	&& ssh-keygen -t rsa -f ./id_rsa \
	&& cd $UHOME/.ssh \
# 这里省懒事，因为是测试，所以直接都用一个 ssh 密钥吧
	&& cat id_rsa.pub > authorized_keys \
	&& chmod 600 authorized_keys

USER root
COPY ./start-run /usr/local/bin/start-run
RUN chmod +x /usr/local/bin/start-run

ENV TERM=xterm-256color
ENTRYPOINT ["sh", "/usr/local/bin/start-run"]

