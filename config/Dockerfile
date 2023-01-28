FROM jupyter/scipy-notebook:latest
# The image index can be found here:
# https://hub.docker.com/r/jupyter/scipy-notebook/tags/

# Begin custom install scripts:

# Escalate privileges to run apt-get
USER root
RUN apt-get update && apt-get -y install apt-utils
RUN apt-get -y install vim-tiny curl less wget
RUN ln -s /usr/bin/vim.tiny /usr/local/bin/vim

# De-escalate
USER $NB_UID

# Install classic notebook
RUN pip install --no-cache-dir nbclassic

# Required libraries for 141

# Required for cs1-libraries
RUN pip install --no-cache-dir ipycanvas
RUN pip install --no-cache-dir ipyevents
RUN pip install --no-cache-dir jupyter-ui-poll 

# Note: we use a forked version of nbgitpuller to loosen some semantics when
# merging. This forked version has additional flags that control some behavior
# we find undesireable in the upstream version. If we revert to the released
# version of nbgitpuller, the flags in config/config.yaml must be updated.
# RUN pip install --no-cache-dir nbgitpuller
RUN pip install --no-cache-dir git+https://github.com/Rhodes-CS-Department/nbgitpuller.git

RUN pip install --no-cache-dir okpy

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

# Install COMP141 libraries
RUN pip install --no-cache-dir git+https://github.com/Rhodes-CS-Department/comp141-libraries.git

# Install theme selector
RUN git clone https://github.com/Rhodes-CS-Department/jupyter_themes.git
RUN jupyter nbextension install jupyter_themes/ --sys-prefix
RUN jupyter nbextension enable jupyter_themes/theme_selector --section='common' --sys-prefix
RUN rm -rf jupyter_themes
