######################################################
#FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu16.04
######################################################f1`

FROM continuumio/anaconda3
# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
# gino updated this line
########################################################
ARG AIRFLOW_VERSION=1.10.9     
########################################################
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow

# gino added the java lines
########################################################
RUN apt-get install -y vim && \ 
    apt-get update 
RUN conda install -c cyclus java-jdk
    #apt-get install -y software-properties-common && \
    #add-apt-repository ppa:webupd8team/java && \
    #apt-get install oracle-java8-installer && \
    #apt-get install -y openjdk-8-jdk && \
    #apt-get install -y ant && \
    #apt-get clean && \
    #rm -rf /var/lib/apt/lists/ && \
    #rm -rf /var/cache/oracle-jdk8-installer;

# Setting JAVA_HOME environment for PySpark operations
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
#RUN export JAVA_HOME
########################################################

# Anaconda's Environment file
COPY config/environment.yml /environment.yml
# gino added this line
########################################################
RUN conda update -n base -c defaults conda 
########################################################
RUN conda env create -f environment.yml
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# pip dependencies
RUN pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis>=2.10.5,<3'

# cleaning it up
RUN if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base
#RUN apt-get update && apt-get install -y gnupg2 && \
#    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-ubuntu1604.pin && \
#    mv cuda-ubuntu1604.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
#    wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda-repo-ubuntu1604-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb && \
#    dpkg -i cuda-repo-ubuntu1604-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb && \
#    apt-key add /var/cuda-repo-10-2-local-10.2.89-440.33.01/7fa2af80.pub && \
#    apt-get update && apt-get -y install cuda 
    

RUN apt-get update && apt-get remove --purge '^nvidia-.*' && \
    apt-get update && apt-get install -y nvidia* && \ 
    apt-get update && apt-get install -y nvidia-cuda* && \
    #prime-select intel && \
    apt-get update && apt-get install -y libcublas-dev && \
    apt-get update && apt-get install -y cuda*
    #&& apt-get install nvidia-docker2
    #systemctl daemon-reload && \
    #&& systemctl restart docker
    
COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}



ENTRYPOINT ["/entrypoint.sh"]

# set default arg for entrypoint
CMD ["webserver"]
