
# OCI Container Utils (oci-utils)

Installs useful CLI tools for working with OCI containers, namely skopeo and oras

## Example Usage

```json
"features": {
    "ghcr.io/joshspicer/features/oci-utils:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| orasVersion | Version of oras to install.  See https://oras.land/cli for details.  Omit for the default pinned version. | string | 0.15.1 |
| skopeoInstallSource | Locations to attempt to install skopeo from.  Choosing 'automatic' will attempt to install from apt first, then homebrew. | string | automatic |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/joshspicer/features/blob/main/src/oci-utils/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
