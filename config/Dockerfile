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

# Required libraries for 141
RUN pip install --no-cache-dir ipycanvas
RUN pip install --no-cache-dir ipyevents
RUN pip install --no-cache-dir nbgitpuller
RUN pip install --no-cache-dir okpy
RUN pip install --no-cache-dir jupyter-ui-poll # 141 libs dependency

# Dependencies for extensions
RUN pip install --no-cache-dir yapf

# Jupyter extensions
RUN pip install --no-cache-dir jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --sys-prefix
# Extensions enabled by default
RUN jupyter nbextension enable code_prettify/code_prettify --sys-prefix
RUN jupyter nbextension enable toggle_all_line_numbers/main --sys-prefix
RUN jupyter nbextension enable execution_dependencies/execution_dependencies --sys-prefix
RUN jupyter nbextension enable freeze/main --sys-prefix
RUN jupyter nbextension enable varInspector/main --sys-prefix
RUN jupyter nbextension enable limit_output/main --sys-prefix
RUN jupyter nbextension enable move_selected_cells/main --sys-prefix
RUN jupyter nbextension enable code_font_size/code_font_size --sys-prefix
RUN jupyter nbextension enable spellchecker/main --sys-prefix

# Optional libraries
RUN pip install --no-cache-dir beautifulsoup4
# Install RISE for slideshows
RUN pip install --no-cache-dir RISE
