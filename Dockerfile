# KEYNOTE: How to build the image solely from this Dockerfile:
# (These commands should be executed in WSL at the repository directory my-julia-build)
# $ docker build -t jbuild -f Dockerfile .
# $ docker tag jbuild okatsn/my-julia-build:latest
# $ docker push okatsn/my-julia-build:latest
#
# Explain:
# - bulid docker image of tag (-t) "jbuild" using file ("-f") "Dockerfile" in the context of current directory (`.` in the end)
# - tag the image 
# - push it to dockerhub
# Why not use devcontainer.json to build?
# - Building image from devcontainer.json creates some additional files, such as those in /home/okatsn/.vscode-server and /home/okatsn/.vscode-server-insiders
# - If there are other container (saying the-target) that was directly built upon this image, and it also has /home/okatsn/.vscode-server but should with different content, the files in source (my-julia-build) is kept, and those in the target are discarded. This is not what we want.
#
# References:
# https://github.com/andferrari/julia_notebook/blob/master/Dockerfile
# https://github.com/marius311/CMBLensing.jl/blob/master/Dockerfile
# https://github.com/MalteBoehm/julia_docker-compose_template/blob/main/Dockerfile
#
#
# KEYNOTE: How to use (please replace $NB_USER, $WORKSPACE_DIR and $VARIANT yourself)
# FROM okatsn/my-julia-build as build-julia
# COPY --from=build-julia /home/okatsn/.julia /home/$NB_USER/.julia
# COPY --from=build-julia /opt/julia-okatsn /opt/julia-okatsn
# COPY --from=build-julia /home/okatsn/Project.toml /home/$NB_USER/$WORKSPACE_DIR
# # Create link in the new machine (based on that /usr/local/bin/ is already in PATH)
# RUN sudo ln -fs /opt/julia-okatsn/bin/julia /usr/local/bin/julia
# 
# Stage 1: Build Julia and related configurations
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

# Install Julia # SETME: Set the julia version here.
ARG VARIANT="1.9.4" 
# ENV JULIA_PATH /opt/julia-${VARIANT}

ENV JULIA_PATH /opt/julia-okatsn
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
# # the following command set `/usr/local/bin/julia` as a link to /opt/julia-${VARIANT}/bin/julia, that
# # in bash type `julia` starts the julia REPL.
# RUN ln -fs /opt/julia-${VARIANT}/bin/julia /usr/local/bin/julia

# Create and Switch to non-root user, and grant necessary permissions
RUN useradd -m -s /bin/bash okatsn && \
    mkdir /home/okatsn/.julia && \
    chown -R okatsn:okatsn /home/okatsn

USER okatsn

# Set working directory
WORKDIR /home/okatsn

# Install Julia packages and set up configuration

RUN julia --project=/home/okatsn -e 'using Pkg; Pkg.update()' \
    && julia -e '\
    using Pkg; \
    Pkg.Registry.add(RegistrySpec(url = "https://github.com/okatsn/OkRegistry.git"))' \
    && julia -e ' \
    using Pkg; \
    Pkg.add(name="IJulia"); \
    Pkg.add(name="OkStartUp"); \
    Pkg.add(name="OhMyREPL"); \
    Pkg.add(name="Revise"); \
    Pkg.add(name="TerminalPager"); \
    Pkg.add(name="Test"); \
    Pkg.add(name="BenchmarkTools"); \
    Pkg.instantiate(); \
    Pkg.build("IJulia"); \
    '
# build IJulia is required to make any jupyter related functions such as quarto
# Add other default packages using an Project.toml

# For OhMyREPL
RUN mkdir -p /home/okatsn/.julia/config
COPY startup.jl /home/okatsn/.julia/config/startup.jl

# # KEYNOTE: For OhMyREPL etc.
# - RUN mkdir -p /home/$NB_USER/.julia/config && cp .devcontainer/startup.jl "$_" # This mkdir all necessary paths and copy files to there in one line. It worked in bash but failed in Dockerfile.
# - Use $HOME instead of /home/$NB_USER will fail! Since $HOME is not recognized as absolute directory!
# - COPY startup.jl in the end to avoid permission error


# End of Stage "my-julia-build"
