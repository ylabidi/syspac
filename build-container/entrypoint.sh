#!/bin/bash
set -euo pipefail

# Import GPG key if provided
if [ -n "${GPG_KEY_DATA-}" ]; then
    if [ -z "${GPG_KEY_ID-}" ]; then
        echo 'ERROR: GPG_KEY_ID is required when GPG_KEY_DATA is provided'
        exit 1
    fi
    echo "Importing GPG key..."
    gpg --import /dev/stdin <<<"${GPG_KEY_DATA}"
    echo "Trusting GPG key..."
    echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "${GPG_KEY_ID}" trust
fi

# Set up repository directory
REPO_ROOT="/repo"
mkdir -p "${REPO_ROOT}"/{x86_64,i686}

# Download existing repository files if they exist
download_repo_files() {
    local arch=$1
    local base_url="https://github.com/${GITHUB_REPOSITORY}/releases/download/repository"
    local dir="${REPO_ROOT}/${arch}"

    echo "Downloading existing repository files for ${arch}..."
    cd "${dir}"

    # Try to download existing database files
    for file in custom.{db,files}{,.tar.gz}; do
        curl -sSfL -o "${file}" "${base_url}/${arch}/${file}" || true
    done

    # Try to download existing packages
    if [ -f custom.db.tar.gz ]; then
        # Extract package filenames from database
        tar -xf custom.db.tar.gz -O | grep -A1 %FILENAME% | grep -v %FILENAME% | while read -r pkg; do
            if [ -n "$pkg" ]; then
                echo "Downloading ${pkg}..."
                curl -sSfL -o "${pkg}" "${base_url}/${arch}/${pkg}" || true
                if [ -n "${GPG_KEY_ID-}" ]; then
                    curl -sSfL -o "${pkg}.sig" "${base_url}/${arch}/${pkg}.sig" || true
                fi
            fi
        done
    fi

    cd - >/dev/null
}

# Download existing repository files for each architecture
for arch in x86_64 i686; do
    download_repo_files "${arch}"
done

# Function to build a package
build_package() {
    local pkg_dir=$1
    local arch=$2

    echo "Building ${pkg_dir} for ${arch}..."

    # Create clean chroot for building
    mkdir -p /build/chroot
    mkarchroot /build/chroot/root base-devel

    # Copy package files to chroot
    cp -r "${pkg_dir}" /build/chroot/root/build

    # Build package in clean chroot
    arch-nspawn /build/chroot/root bash -c "cd /build/$(basename ${pkg_dir}) && makepkg -s --noconfirm"

    # Move built packages to repository
    mv "${pkg_dir}"/*.pkg.tar.zst "${REPO_ROOT}/${arch}/"
}

# Function to update repository database
update_repo_db() {
    local arch=$1
    local dir="${REPO_ROOT}/${arch}"

    echo "Updating repository database for ${arch}..."
    cd "${dir}"

    # Remove old signatures if they exist
    rm -f *.sig

    # Sign packages if GPG key is available
    if [ -n "${GPG_KEY_ID-}" ]; then
        # Sign packages
        for pkg in *.pkg.tar.zst; do
            if [ -f "${pkg}" ]; then
                gpg --detach-sign --use-agent -u "${GPG_KEY_ID}" "${pkg}"
            fi
        done

        # Create/update database with signatures
        repo-add -s -k "${GPG_KEY_ID}" -n -R custom.db.tar.gz *.pkg.tar.zst
    else
        # Create/update database without signatures
        repo-add -n -R custom.db.tar.gz *.pkg.tar.zst
    fi

    # Create symbolic links
    ln -sf custom.db.tar.gz custom.db
    ln -sf custom.files.tar.gz custom.files

    cd - >/dev/null
}

# Build changed packages
if [ -n "${CHANGED_PACKAGES-}" ]; then
    for pkg in ${CHANGED_PACKAGES}; do
        if [ -d "/build/${pkg}" ]; then
            for arch in x86_64 i686; do
                build_package "/build/${pkg}" "${arch}"
            done
        else
            echo "WARNING: Package directory ${pkg} not found"
        fi
    done
fi

# Update repository databases
for arch in x86_64 i686; do
    update_repo_db "${arch}"
done

echo "Build and repository update completed successfully"
