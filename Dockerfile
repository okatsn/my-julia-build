# KEYNOTE: How to build the image solely from this Dockerfile:
# (In MyJuliaSpace/; change "latest" to any other tag names)
# $ docker build -t myjspace -f .devcontainer/Dockerfile .
# $ docker tag myjspace okatsn/my-julia-space:latest
# $ docker push okatsn/my-julia-space:latest
#
# Why not use devcontainer.json to build?
# - Building image from devcontainer.json creates some additional files, such as those in /home/okatsn/.vscode-server and /home/okatsn/.vscode-server-insiders
# - If there are other container (saying the-target) built upon this image, and it also has /home/okatsn/.vscode-server but should with different content, the files in source (my-julia-space) is kept, and those in the target are discarded. This is not what we want.
#
# References:
# https://github.com/andferrari/julia_notebook/blob/master/Dockerfile
# https://github.com/marius311/CMBLensing.jl/blob/master/Dockerfile
# https://github.com/MalteBoehm/julia_docker-compose_template/blob/main/Dockerfile
#
#
# KEYNOTE: How to use (please replace NEWUSER and WORKSPACE yourself)
# FROM okatsn/my-julia-build as build-julia
# COPY --from=build-julia /usr/local/bin/julia /usr/local/bin/julia
# COPY --from=build-julia /home/okatsn/.julia /home/NEWUSER/.julia
# COPY /home/okatsn/Project.toml /home/NEWUSER/WORKSPACE
#
# Stage 1: Build Julia and related configurations
FROM ubuntu AS build-julia

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

# Switch to non-root user
USER okatsn

# Set working directory
WORKDIR /home/okatsn

# Install Julia packages and set up configuration
RUN julia -e 'using Pkg; Pkg.update()' \
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
