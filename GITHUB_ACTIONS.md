# GitHub Actions Setup Guide

This guide explains how to set up GitHub Actions to automatically build and deploy your nginx gateway Docker image to Docker Hub.

## Prerequisites

1. **GitHub Repository**: Your code must be in a GitHub repository
2. **Docker Hub Account**: You need a Docker Hub account to push images
3. **Repository Secrets**: Configure the required secrets in your GitHub repository

## Required GitHub Secrets

Navigate to your repository → Settings → Secrets and variables → Actions, then add these secrets:

### Docker Hub Authentication
| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | `yourusername` |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password!) | `dckr_pat_abc123...` |

### Optional Features
| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| None | All core features work with just Docker Hub credentials | - |

## How to Get Docker Hub Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Choose "Public Repo Read, Write" permissions
5. Copy the generated token and add it as `DOCKERHUB_TOKEN` secret

## Workflows Overview

### 1. Docker Build (`docker-build.yml`)
**Triggers:**
- GitHub releases/tags
- Manual workflow dispatch

**Features:**
- Multi-platform builds (AMD64, ARM64)
- Automatic tagging based on release version
- Docker layer caching for faster builds
- Container testing
- Docker Hub description updates

### 2. Release (`release.yml`)
**Triggers:**
- GitHub release publication

**Features:**
- Multi-platform builds including ARM v7
- Multiple image tags (version, major.minor, latest)
- Release notes enhancement with Docker info
- Optimized for production releases

## Docker Image Tagging Strategy

### Version Tags (for releases)
- `v1.2.3` → `1.2.3`, `1.2`, `1`, `latest`
- `v2.0.0-beta.1` → `2.0.0-beta.1`

### Manual Dispatch Tags
- Custom tag name specified during manual trigger

## Manual Workflow Dispatch

You can manually trigger builds with custom parameters:

1. Go to Actions tab in your repository
2. Select "Build and Push Docker Image"
3. Click "Run workflow"
4. Specify custom tag and push options

## Example Usage After Setup

Once configured, your workflow will automatically:

### On Tag Creation (Release)
```bash
git tag v1.0.0
git push origin v1.0.0
# → Builds and pushes:
#   - yourusername/nginx-gateway:1.0.0
#   - yourusername/nginx-gateway:1.0
#   - yourusername/nginx-gateway:1
#   - yourusername/nginx-gateway:latest
```

### Manual Deployment
```bash
# Go to GitHub Actions → Build and Push Docker Image → Run workflow
# Specify custom tag: "staging"
# → Builds and pushes yourusername/nginx-gateway:staging
```

## Using Your Docker Image

After the workflow runs, you can use your image:

```bash
# Pull your image
docker pull yourusername/nginx-gateway:latest

# Run your gateway
docker run -d \
  --name nginx-gateway \
  -p 80:80 -p 443:443 \
  -e DOMAIN=your-domain.com \
  -e INTERNAL_MAIN_HOST=your-app \
  -e INTERNAL_MAIN_PORT=8000 \
  yourusername/nginx-gateway:latest
```

## Security Features

### Basic Security
- **Secure Secrets**: Docker Hub credentials stored as GitHub secrets
- **Multi-platform Support**: Builds for AMD64, ARM64, and ARM v7
- **Container Testing**: Validates image functionality before deployment

## Monitoring and Maintenance

### Build Status
Monitor your builds in the Actions tab:
- ✅ Green: Build succeeded
- ❌ Red: Build failed
- 🟡 Yellow: Build in progress

### Manual Maintenance
You can manually:
- Update base images by editing the Dockerfile
- Monitor Docker Hub for your published images
- Check build logs for any issues

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets
   - Ensure token has correct permissions
   - Check token hasn't expired

2. **Build Failures**
   - Check Dockerfile syntax
   - Verify all COPY sources exist
   - Review build logs in Actions tab

3. **Multi-platform Build Issues**
   - Ensure base image supports target platforms
   - Check for platform-specific dependencies

4. **Push Failures**
   - Verify repository exists on Docker Hub
   - Check repository permissions
   - Ensure namespace matches username

### Getting Help

- Check workflow logs in the Actions tab
- Review the GitHub Actions documentation
- Examine specific step outputs for error details

## Advanced Configuration

### Custom Registry
To use a different registry, update the workflows:

```yaml
env:
  REGISTRY: ghcr.io  # or your registry
  IMAGE_NAME: nginx-gateway
```

### Additional Platforms
Add more platforms in the build step:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7,linux/386
```

### Custom Build Args
Add build arguments:

```yaml
build-args: |
  CUSTOM_ARG=value
  ANOTHER_ARG=value
```

## Best Practices

1. **Use Semantic Versioning**: Tag releases as `v1.2.3`
2. **Monitor Security**: Review security scan results regularly
3. **Test Locally**: Test Docker builds locally before pushing
4. **Keep Secrets Secure**: Rotate tokens regularly
5. **Document Changes**: Use clear commit messages and PR descriptions
