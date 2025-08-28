# Use a specific Long-Term Support (LTS) version of Ubuntu for a stable, secure base.
FROM ubuntu:22.04

# Set versions as build arguments for easy updates.
ARG NODE_VERSION="20"

# Set environment variables for non-interactive installation and to add pipx to the PATH.
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:/home/devuser/.local/bin:${PATH}"


# 1. INSTALL SYSTEM DEPENDENCIES & APPLY SECURITY PATCHES
# --------------------------------------------------------
# Start by updating the package index and upgrading all installed packages.
# This ensures we have the latest security patches for the base image.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    sudo \
    python3-pip \
    python3-venv && \
    # Set up the NodeSource repository for a modern version of Node.js.
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list


# 2. INSTALL DEVELOPMENT TOOLS
# --------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g prettier prettier-plugin-nextflow && \
    pip install --no-cache-dir pipx && \
    pipx install nf-core nf-test


# 3. CREATE NON-ROOT USER
# -------------------------
# Create a standard user 'devuser' and grant passwordless sudo privileges.
RUN useradd -m -s /bin/bash -G sudo devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


# 4. CLEANUP
# ----------
# Clean the apt cache to minimize the final image size.
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# 5. FINAL CONFIGURATION
# ------------------------
USER devuser
WORKDIR /home/devuser
CMD ["/bin/bash"]