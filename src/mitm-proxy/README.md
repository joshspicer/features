
# mitm-proxy



## Example Usage

```json
"features": {
    "ghcr.io/joshspicer/features/mitm-proxy:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of MITM proxy to install (auto-detects if 'latest'). See https://mitmproxy.org/downloads/ for available versions. | string | latest |
| installRootCerts | Install root CA into system store (required to proxy HTTPS requests). | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/joshspicer/features/blob/main/src/mitm-proxy/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
