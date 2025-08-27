# Compose Watch Guide for Keycloak Development

This guide explains how to use Docker Compose Watch for efficient development with your Keycloak project.

## Overview

Compose Watch has been configured to provide different behaviors for different types of files:

### Sync Actions (Hot Reload)
These files are synchronized in real-time without rebuilding the container:

- **Theme Files** (`./themes/src/main/resources/theme/usai/`)
  - All FreeMarker templates (`.ftl`)
  - CSS files
  - JavaScript files
  - Images and other assets
  - **Target**: `/opt/keycloak/themes/usai/`

- **WebAuthn Configuration** (`./webauthn-config/`)
  - Shell scripts
  - Configuration files
  - **Target**: `/opt/keycloak/webauthn-config/`

- **Entrypoint Script** (`./entrypoint.sh`)
  - **Target**: `/opt/keycloak/bin/entrypoint.sh`

### Rebuild Actions (Full Container Rebuild)
These changes trigger a complete image rebuild:

- **Maven POM Files**
  - `./pom.xml`
  - `./keycloak-login.gov-integration/pom.xml`
  - `./themes/pom.xml`
  - `./extensions/keycloak-api-key-demo/api-key-module/pom.xml`
  - `./extensions/keycloak-api-key-demo/dashboard-service/pom.xml`

- **Java Source Code**
  - `./keycloak-login.gov-integration/src/`
  - `./extensions/keycloak-api-key-demo/`

- **Dockerfile Changes**
  - `./Dockerfile`

## Usage

### Starting with Watch Mode

To start your development environment with watch mode enabled:

```bash
# Start services with watch mode
docker compose up --watch

# Or start in detached mode with watch
docker compose up --watch -d
```

### Using Dedicated Watch Command

If you prefer to separate application logs from watch events:

```bash
# Start services normally
docker compose up -d

# Run watch in a separate terminal
docker compose watch
```

### Stopping Watch Mode

```bash
# Stop all services
docker compose down

# Or just stop watch (if using separate command)
# Ctrl+C in the watch terminal
```

## Development Workflows

### Theme Development
1. Start the services with watch: `docker compose up --watch`
2. Edit any file in `themes/src/main/resources/theme/usai/`
3. Changes are automatically synced to the container
4. Refresh your browser to see changes immediately

**Example**: Editing `login.ftl` or `usai.css` will be reflected instantly.

### Extension Development
1. Start the services with watch: `docker compose up --watch`
2. Edit Java source files in `keycloak-login.gov-integration/src/`
3. The container will automatically rebuild and restart
4. Wait for the rebuild to complete before testing

**Example**: Modifying login.gov integration code will trigger a full rebuild.

### Configuration Changes
1. Edit WebAuthn scripts in `webauthn-config/`
2. Changes are synced immediately
3. You may need to restart Keycloak manually if the configuration affects runtime behavior

## File Patterns and Ignores

### Automatically Ignored Files
- `**/*.class` - Compiled Java classes
- `**/target/` - Maven build directories
- `**/*.log` - Log files
- Files matching `.dockerignore` patterns

### Performance Tips

1. **Theme Development**: Use sync for rapid iteration on UI changes
2. **Extension Development**: Expect rebuilds to take time due to Maven compilation
3. **Mixed Development**: Consider using separate terminals for different types of changes

## Troubleshooting

### Watch Not Detecting Changes
- Ensure files are within the watched paths
- Check that files aren't being ignored by patterns
- Verify Docker has file system access permissions

### Rebuild Taking Too Long
- Check if Maven dependencies need to be downloaded
- Consider using Maven daemon for faster builds
- Ensure adequate system resources

### Sync Not Working
- Verify the target paths exist in the container
- Check container user permissions
- Ensure the container is running

### Common Issues

1. **Permission Errors**: The container runs as the `keycloak` user, ensure synced files have appropriate permissions

2. **Path Mismatches**: Verify that source paths exist and target paths are correct in the container

3. **Build Context**: Large build contexts can slow down rebuilds - ensure `.dockerignore` is properly configured

## Best Practices

1. **Use Sync for Rapid Iteration**: Theme files, scripts, and configuration
2. **Use Rebuild for Structural Changes**: Java code, dependencies, Dockerfile
3. **Monitor Resource Usage**: Watch mode can be resource-intensive
4. **Test Thoroughly**: Always test changes in a clean environment before deployment

## Example Development Session

```bash
# Start development environment
docker compose up --watch

# In another terminal, make theme changes
echo "/* Updated styles */" >> themes/src/main/resources/theme/usai/login/resources/css/usai.css

# Changes are synced immediately, refresh browser to see updates

# Make Java changes (triggers rebuild)
# Edit keycloak-login.gov-integration/src/main/java/...

# Wait for rebuild to complete, then test changes
```

## Integration with IDEs

### VS Code
- Use the Docker extension to monitor container status
- Configure file watchers to complement Compose Watch
- Use integrated terminal for watch commands

### IntelliJ IDEA
- Configure Docker integration for container management
- Use built-in Maven integration alongside Compose Watch
- Monitor build logs through Docker tool window

## Monitoring Watch Events

Watch events are logged to the console when using `docker compose up --watch`. Look for:
- `Syncing` messages for file synchronization
- `Rebuilding` messages for container rebuilds
- Error messages for failed operations

This setup optimizes your development workflow by providing immediate feedback for UI changes while ensuring proper rebuilds for code changes.
