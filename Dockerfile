# KEYNOTE: How to build the image solely from this Dockerfile:
# (In MyJuliaSpace/; change "latest" to any other tag names)
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
# COPY --from=build-julia /usr/local/bin/julia /usr/local/bin/julia
# COPY --from=build-julia /home/okatsn/.julia /home/$NB_USER/.julia
# COPY --from=build-julia /opt/julia-* /opt/julia
# COPY /home/okatsn/Project.toml /home/$NB_USER/$WORKSPACE_DIR
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

# Set environment variables
ENV JULIA_PKG_DEVDIR=${JULIA_PKG_DEVDIR}

# Install Julia
RUN mkdir /opt/julia-${VARIANT} \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/`echo ${VARIANT} | cut -d. -f 1,2`/julia-${VARIANT}-linux-x86_64.tar.gz | tar zxf - -C /opt/julia-${VARIANT} --strip=1 \
    && ln -fs /opt/julia-${VARIANT}/bin/julia /usr/local/bin/julia

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
