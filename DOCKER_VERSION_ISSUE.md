# Docker Version Compatibility Issue

## Problem

When deploying the Hyperledger Fabric chaincode, you may encounter this error:

```
Error: chaincode install failed with status: 500 - failed to invoke backing implementation of 'InstallChaincode': could not build chaincode: docker build failed: docker image build failed: write unix @->/run/docker.sock: write: broken pipe
```

## Root Cause

This error is caused by **incompatibility between Hyperledger Fabric and Docker Engine version 29+**.

The Hyperledger Fabric peer uses a Go Docker client that has not been updated to work with the changes in Docker Engine 29's socket handling. This results in broken pipe errors when Fabric tries to build chaincode images.

## Solution

### Recommended: Downgrade Docker Engine to v28

The most reliable solution is to downgrade Docker Engine to version 28 or earlier.

#### For Ubuntu/Debian:

1. **Check your current Docker version:**
   ```bash
   docker version
   ```

2. **Uninstall current Docker:**
   ```bash
   sudo apt-get remove docker-ce docker-ce-cli containerd.io
   ```

3. **Install Docker Engine 28:**
   ```bash
   sudo apt-get update
   sudo apt-get install docker-ce=5:28.0.* docker-ce-cli=5:28.0.* containerd.io
   ```

4. **Verify the installation:**
   ```bash
   docker version
   ```

5. **Restart your network and try deployment again:**
   ```bash
   ./scripts/cleanup.sh
   ./scripts/start-network.sh
   ./scripts/deploy-chaincode.sh
   ```

#### For other operating systems:

See the [official Docker documentation](https://docs.docker.com/engine/install/) for version-specific installation instructions.

### Alternative: Use Manual Deployment

If you cannot downgrade Docker immediately, you can try the manual deployment script which includes retry logic and additional error handling:

```bash
./scripts/deploy-chaincode-manual.sh
```

## Prevention

The deployment scripts now automatically check for Docker version compatibility and will warn you if an incompatible version is detected.

## References

- [Hyperledger Fabric Issue #5350](https://github.com/hyperledger/fabric/issues/5350)
- [Stack Overflow Discussion](https://stackoverflow.com/questions/79834736/deploying-chaincode-failed-socket-is-broken)

## Future Updates

Hyperledger Fabric maintainers are aware of this issue and will likely update the Docker client library in future releases to restore compatibility with Docker Engine 29+.

Until then, **Docker Engine v28 or earlier is required** for successful chaincode deployment.
