# Artix Linux Custom Repository

This repository serves as a custom package repository for Artix Linux, using GitHub releases as the package distribution mechanism.

## Repository Structure

Each package is managed as a git submodule, allowing for:
- Easy upstream tracking when packages are forked from AUR
- Independent version control for each package
- Simple synchronization with upstream sources

### Adding a New Package

1. Fork the upstream repository (if available) or create a new one
2. Add it as a submodule:
```bash
git submodule add <repository-url> <package-name>
git commit -m "Add <package-name> as submodule"
```

### Updating Packages

To update all submodules to their latest versions:
```bash
git submodule update --remote --merge
git commit -m "Update package submodules"
```

To update a specific package:
```bash
cd <package-name>
git pull origin master
cd ..
git commit -m "Update <package-name>"
```

## Using the Repository

Add the following to your `/etc/pacman.conf`:

```ini
[custom]
Server = https://github.com/yourusername/aur/releases/download/repository/x86_64
SigLevel = Optional TrustAll  # Change once signing is configured
```

Then update your package database:
```bash
sudo pacman -Sy
```

You can now install packages from this repository:
```bash
sudo pacman -S package-name
```

## Package Guidelines

All packages should:
- Follow [Arch Packaging Standards](https://wiki.archlinux.org/title/Arch_package_guidelines)
- Be tested on Artix Linux
- Include proper license information
- Have clean and well-documented PKGBUILDs

## Automated Builds

When changes are pushed to master:
1. Changed submodules are detected
2. Packages are built in a clean Artix Linux environment
3. Built packages are signed (if configured)
4. The repository release is updated

## Contributing

1. Fork this repository
2. Create a new branch
3. Make your changes:
   - Add/update submodules
   - Modify package builds
4. Submit a pull request

## License

- Package build scripts (PKGBUILDs) are licensed under GPL-3.0 unless otherwise specified
- Individual packages may have different licenses as specified in their respective PKGBUILDs

## Troubleshooting

Build logs are available in GitHub Actions artifacts for debugging purposes.

Common issues:
- Missing dependencies: Add them to the PKGBUILD's makedepends
- Submodule issues: Try `git submodule update --init --recursive`
- Build failures: Check the Actions tab for detailed logs