#FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04
#FROM nvidia/cuda:10.0-base-ubuntu16.04
#FROM nvidia/cuda:latest
#FROM nvidia/cuda:10.2-base-ubuntu16.04
#FROM nvcr.io/nvidia/tensorflow:20.01-tf1-py3
#FROM nvcr.io/nvidia/tensorflow:19.12-tf1-py3
FROM nvcr.io/nvidia/tensorflow:19.02-py3




#CMD ["bash"]

# Install Airflow
#######################################################################################################
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

# Install Anaconda
CMD ["/bin/bash"]
RUN apt-get update && apt-get -y install wget
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh -O ~/anaconda.sh && /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy
RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion && \
    apt-get clean

ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# gino added the java lines
########################################################
RUN apt-get install -y vim && \
    apt-get update
RUN conda install -c cyclus java-jdk
########################################################

# Anaconda's Environment file
COPY config/environment.yml environment.yml
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

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/
RUN cd /usr/local/cuda/lib64/ && \
    ln libcudart.so.10.2 libcudart.so.10.0 && \
    ln libcufft.so.10 libcufft.so.10.0 && \
    ln libcurand.so.10 libcurand.so.10.0 && \
    ln libcusolver.so.10 libcusolver.so.10.0 && \
    ln libcusparse.so.10 libcusparse.so.10.0 && \
    ln libcublas.so.10.0 libcublas.so.10.0
    
COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}



ENTRYPOINT ["/entrypoint.sh"]

# set default arg for entrypoint
CMD ["webserver"]
