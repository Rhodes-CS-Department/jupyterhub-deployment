FROM jupyter/scipy-notebook:latest
# The image index can be found here:
# https://hub.docker.com/r/jupyter/scipy-notebook/tags/

# Begin custom install scripts:

# Escalate privileges to run apt-get
USER root
RUN apt-get update && apt-get -y install apt-utils
RUN apt-get -y install vim-tiny curl less
RUN ln -s /usr/bin/vim.tiny /usr/local/bin/vim

# De-escalate
USER $NB_UID
RUN pip install --no-cache-dir ipycanvas
RUN pip install --no-cache-dir ipyevents
RUN pip install --no-cache-dir nbgitpuller
RUN pip install --no-cache-dir okpy
