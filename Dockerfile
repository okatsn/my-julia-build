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

# Install quarto (failed)
# - Noted that gdebi-core is required.
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb \
    && gdebi --non-interactive quarto-linux-amd64.deb

# Install Julia
ARG VARIANT="1.9.4"
ARG JULIA_PKG_DEVDIR="/home/jovyan/.julia/dev"

# Set environment variables
ENV JULIA_PKG_DEVDIR=${JULIA_PKG_DEVDIR}

# Install Julia
RUN mkdir /opt/julia-${VARIANT} \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/`echo ${VARIANT} | cut -d. -f 1,2`/julia-${VARIANT}-linux-x86_64.tar.gz | tar zxf - -C /opt/julia-${VARIANT} --strip=1 \
    && ln -fs /opt/julia-${VARIANT}/bin/julia /usr/local/bin/julia

# Switch to non-root user
USER jovyan

# Set working directory
WORKDIR /home/jovyan

# Install Julia packages and set up configuration
RUN julia -e 'using Pkg; Pkg.update()' \
    && julia -e 'using Pkg; Pkg.Registry.add(RegistrySpec(url = "https://github.com/okatsn/OkRegistry.git"))' \
    && julia -e 'using Pkg; Pkg.add(name="IJulia"); Pkg.build("IJulia")'

# For OhMyREPL
RUN mkdir -p /home/jovyan/.julia/config
COPY .devcontainer/startup.jl /home/jovyan/.julia/config/startup.jl

# End of Stage 1
