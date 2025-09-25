FROM artixlinux/artixlinux:base-dinit

# Install required packages
RUN pacman -Syu --noconfirm --needed \
    base-devel \
    git \
    wget \
    python \
    && rm -rf /var/cache/pacman/pkg/*

# Add build user and give passwordless sudo access
RUN useradd -m -G wheel builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "Defaults env_keep += \"GNUPGHOME\"" >> /etc/sudoers

# Create build directories
RUN mkdir -p /build /repo && \
    chown -R builder:builder /build /repo

# Set up GPG for package signing
RUN mkdir -p /etc/pacman.d/gnupg && \
    pacman-key --init && \
    pacman-key --populate artix

# Switch to build user for subsequent operations
USER builder
WORKDIR /build

# Set up build environment variables
ENV GNUPGHOME="/home/builder/.gnupg"
ENV PACKAGER="Artix Custom Repository <custom@artixlinux.org>"

# Create GPG directory for builder
RUN mkdir -p ${GNUPGHOME} && \
    chmod 700 ${GNUPGHOME}

# Copy entrypoint script
COPY --chown=builder:builder entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/build", "/repo"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
