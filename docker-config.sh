export NB_UID=1000
export NB_GID=1000

# =========== How to use it locally ===========
# # # In Dockerfile
# 
# ARG NB_USER=jovyan
# ARG NB_UID
# ARG NB_GID
# 
# # Include the configuration
# COPY docker-config.sh /tmp/docker-config.sh
# RUN chmod +x /tmp/docker-config.sh && /bin/bash -c "/tmp/docker-config.sh"
# 
# # Use the variables
# RUN useradd -m -u $NB_UID -g $NB_GID -s /bin/bash $NB_USER
# 
# # Continue with other instructions

# KEYNOTE: 
# - `-m`: ensures that a home directory is created for the new user
# - `-s /bin/bash`: This option specifies the login shell for the new user. This is not strictly required.

# =========== How to use a cloud one ==========
# # # Dockerfile
# 
# ARG NB_USER=jovyan
# ARG NB_UID
# ARG NB_GID
# 
# # Download the configuration script from GitHub
# RUN curl -o /tmp/docker-config.sh -L https://raw.githubusercontent.com/yourusername/yourrepo/main/docker-config.sh
# 
# # Make it executable and execute
# RUN chmod +x /tmp/docker-config.sh && /bin/bash -c "/tmp/docker-config.sh"
# 
# # Use the variables
# RUN useradd -m -u $NB_UID -g $NB_GID -s /bin/bash $NB_USER
# 
# # Continue with other instructions
