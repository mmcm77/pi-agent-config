# Pi agent configuration

This directory is the local source of truth for the reviewed Pi configuration. The `main` branch is backed up to the private GitHub repository [`mmcm77/pi-agent-config`](https://github.com/mmcm77/pi-agent-config).

## Tracked

- System and appended system prompts
- Global extensions and reusable skills
- Non-secret settings
- Exact Pi, Node, npm, and package versions
- Reproducible package patches
- Installation and verification scripts

The root `.gitignore` uses an allowlist. Credentials, project trust decisions, sessions, indexes, package installations, generated model catalogs, binaries, and backups remain untracked.

## Verify the current setup

```bash
scripts/verify-config.sh
```

The check verifies the Pi, Node, and npm versions; exact package source; installed package version and integrity; the reviewed trust patch; required configuration files; the Git privacy boundary; and a clean Pi RPC startup.

## Reproduce the setup

Install the Pi and Node versions recorded in `versions.json`, clone this repository as `~/.pi/agent`, authenticate Pi locally, and run:

```bash
scripts/install-config.sh
```

Authentication and project trust are deliberately local and must not be restored from Git.

## Review an upgrade

1. Review the Pi or package changelog and source changes.
2. Update the exact version in `settings.json` and `versions.json`.
3. Install the reviewed version.
4. Recreate or remove the package patch if upstream behavior changed.
5. Run `scripts/verify-config.sh` and relevant workflow tests.
6. Commit the configuration and verification evidence together.

Do not replace exact package versions with ranges. Pi skips versioned package specs during package updates, preventing an unrelated `pi update --extensions` or `pi update --all` from changing reviewed orchestration code.
