# KEYNOTE: How to build the image solely from this Dockerfile:
# (These commands should be executed in WSL at the repository directory my-julia-build)
# $ docker-compose build
# $ docker tag jbuild okatsn/my-julia-build:latest
# $ docker push okatsn/my-julia-build:latest
#
# Explain:
# - bulid docker image of tag (-t) "jbuild" using file ("-f") "Dockerfile" in the context of current directory (`.` in the end)
# - tag the image 
# - push it to dockerhub
# Why not use devcontainer.json to build (saying `$ docker-compose -f .devcontainer/docker-compose.yml build`)?
# - Building image from devcontainer.json creates some additional files, such as those in /home/okatsn/.vscode-server and /home/okatsn/.vscode-server-insiders
# - If there are other container (saying the-target) that was directly built upon this image, and it also has /home/okatsn/.vscode-server but should with different content, the files in source (my-julia-build) is kept, and those in the target are discarded. This is not what we want.
#
# References:
# https://github.com/andferrari/julia_notebook/blob/master/Dockerfile
# https://github.com/marius311/CMBLensing.jl/blob/master/Dockerfile
# https://github.com/MalteBoehm/julia_docker-compose_template/blob/main/Dockerfile
#
#
# KEYNOTE: How to use (please replace $NB_USER, $WORKSPACE_DIR and $VARIANT yourself). $JULIA_PROJECT is something like "v1.10".
# FROM okatsn/my-julia-build:latest as build-julia
# # (at USER root). Refer .env file of the last stage (i.e., my-tex-life) for NB_UID and NB_GID; or define your NB_UID and NB_GID for this build in .env, and include it in docker-compose.yml as args.
# COPY --from=build-julia --chown=$NB_UID:$NB_GID /home/okatsn/.julia /home/$NB_USER/.julia
# COPY --from=build-julia --chown=$NB_UID:$NB_GID /opt/julia-okatsn /opt/julia-okatsn
# # Create link in the new machine (based on that /usr/local/bin/ is already in PATH)
# RUN ln -fs /opt/julia-okatsn/bin/julia /usr/local/bin/julia
# # Build IJulia
# RUN julia -e 'using Pkg; Pkg.update(); Pkg.instantiate(); Pkg.build("IJulia");' 



# Stage 1: Build Julia and related configurations
# SETME: Ubuntu version of build-julia
FROM ubuntu:focal-20200703 AS build-julia
# CHECKPOINT: this version of ubuntu is sticked to https://hub.docker.com/r/jupyter/base-notebook/dockerfile that https://hub.docker.com/r/jupyter/minimal-notebook/dockerfile uses.

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary tools
RUN apt-get update && apt-get -y install \
    gdebi-core \
    curl \
    tar \
    git

# Install Julia 
# SETME: Set the julia version here.
# !!! note Also replace "v1.10" since there are probably hard codes elsewhere.
ARG VARIANT="1.10.0" 
ARG JULIA_PROJECT=v1.10
# KEYNOTE: JULIA_PROJECT must match the [default LOAD_PATH pattern](https://docs.julialang.org/en/v1/base/constants/#Base.LOAD_PATH). Following default is less prone to error and minimize the effort of later-stage docker image building process.

ARG OKATSN_JULIA_ENVS=/home/okatsn/.julia/environments
# # Don't add `@`, @v1.10 will create a folder "@v1.10".

# # [JULIA_PROJECT has the same effect as `--project` option](https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_PROJECT).
# # Both JULIA_PROJECT and JULIA_LOAD_PATH seems to be set in order to start julia using my Project.toml
# # See https://stackoverflow.com/questions/53613663/what-is-in-julia-project-command-line-option
# # CHECKPOINT: However, set JULIA_PROJECT and JULIA_LOAD_PATH seems to be prone to error or unexpected results; I continuously encounter error and give up.
# ENV JULIA_PROJECT=${JULIA_PROJECT}
# ENV JULIA_LOAD_PATH=${OKATSN_JULIA_ENVS}/${JULIA_PROJECT}




# ENV JULIA_PATH /opt/julia-${VARIANT}
ENV JULIA_PATH /opt/julia-okatsn
# !!! note Also replace "julia-okatsn" since there are probably hard codes elsewhere.
# ENV PATH $JULIA_PATH/bin:$PATH
# - Install in JULIA_PATH 
# - the executable is $JULIA_PATH/bin/julia
# - Add $JULIA_PATH/bin to PATH is not required if a link from /usr/local/bin/julia to $JULIA_PATH/bin/julia is established (i.e., `ln -fs $JULIA_PATH/bin/julia /usr/local/bin/julia`). 

# Set environment variables
ENV JULIA_PKG_DEVDIR=${JULIA_PKG_DEVDIR}

# Install Julia
RUN mkdir $JULIA_PATH \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/`echo ${VARIANT} | cut -d. -f 1,2`/julia-${VARIANT}-linux-x86_64.tar.gz | tar zxf - -C $JULIA_PATH --strip=1 \
    && ln -fs $JULIA_PATH/bin/julia /usr/local/bin/julia

# # For Julia installed under /opt/julia-${VARIANT}/bin/julia, 
# # the following command set `/usr/local/bin/julia` as a link to /opt/julia-${VARIANT}/bin/julia, that in bash type `julia` starts the julia REPL.
#
# You can also refer this: https://github.com/docker-library/julia/blob/154363df0b038fb8a5e74bb97bbed3fb8faea7ca/1.9/bullseye/Dockerfile

# Create and Switch to non-root user, and grant necessary permissions
ARG NB_GID="to be replaced by that in docker-compose.yml"
ARG NB_UID="to be replaced by that in docker-compose.yml"
RUN useradd -m -u $NB_UID -g $NB_GID -s /bin/bash okatsn && \
    mkdir /home/okatsn/.julia && \
    chown -R $NB_UID:$NB_GID /home/okatsn
# CHECKPOINT: It does not properly set the permission.

USER okatsn

# Set working directory
WORKDIR /home/okatsn

# Install Julia packages and set up configuration

RUN julia -e 'using Pkg; Pkg.update()' \
    && julia -e '\
    using Pkg; \
    Pkg.Registry.add(RegistrySpec(url = "https://github.com/okatsn/OkRegistry.git"))'
# KEYNOTE: It is effortless to add any package dependencies here.
# KEYNOTE: Don't build IJulia or add packages before the final stage
# - The build step of IJulia is required to make any jupyter related functions such as quarto; it involves linking Julia with the Jupyter notebook infrastructure, and IJulia relies on the Conda.jl package to manage the Jupyter installation.
# - Thus, it is prone to error or effortless if the layer of building IJulia is in the stage other than the final stage when trying to build a multi-stage Docker image, because each stage is a different machine/system.
# - Copy only the Project.toml instead of add packages and move them to a new machine.

# For OhMyREPL
ARG TARGET_PROJECTTOML=${OKATSN_JULIA_ENVS}/${JULIA_PROJECT}/Project.toml
RUN mkdir -p /home/okatsn/.julia/config && \
    mkdir -p ${OKATSN_JULIA_ENVS}/${JULIA_PROJECT} && \
    rm -f $TARGET_PROJECTTOML

COPY startup.jl /home/okatsn/.julia/config/startup.jl
COPY Project.toml $TARGET_PROJECTTOML
# # KEYNOTE: For OhMyREPL etc.
# - RUN mkdir -p /home/$NB_USER/.julia/config && cp .devcontainer/startup.jl "$_" # This mkdir all necessary paths and copy files to there in one line. It worked in bash but failed in Dockerfile.
# - Use $HOME instead of /home/$NB_USER will fail! Since $HOME is not recognized as absolute directory!
# - COPY startup.jl in the end to avoid permission error


# End of Stage "my-julia-build"
