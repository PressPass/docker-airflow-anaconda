# docker-airflow-anaconda
This repository contains **Dockerfile** of [apache-airflow](https://github.com/apache/incubator-airflow) for [Docker](https://www.docker.com/)'s.

## Informations

* Based on Anaconda 3 (continuumio/anaconda3) official Image and uses the official [Postgres](https://hub.docker.com/_/postgres/) as backend and [Redis](https://hub.docker.com/_/redis/) as queue and the [Annoy library](https://github.com/spotify/annoy) for Aproximate K-Nearest Neighbors searches.
* Install [Docker](https://www.docker.com/)
* Install [Docker Compose](https://docs.docker.com/compose/install/)
* Following the Airflow release from [Python Package Index](https://pypi.python.org/pypi/apache-airflow)
