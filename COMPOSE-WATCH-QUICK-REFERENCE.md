# Compose Watch Quick Reference

## Essential Commands

```bash
# Start with watch mode
docker compose up --watch

# Start detached with watch
docker compose up --watch -d

# Separate watch command
docker compose up -d
docker compose watch

# Stop everything
docker compose down
```

## File Change Behaviors

| File Type | Action | Speed | Use Case |
|-----------|--------|-------|----------|
| `themes/src/main/resources/theme/usai/**` | **sync** | ⚡ Instant | UI development |
| `webauthn-config/**` | **sync** | ⚡ Instant | Config changes |
| `entrypoint.sh` | **sync** | ⚡ Instant | Script updates |
| `**/*.java` | **rebuild** | 🐌 ~2-5 min | Code changes |
| `**/pom.xml` | **rebuild** | 🐌 ~2-5 min | Dependencies |
| `Dockerfile` | **rebuild** | 🐌 ~2-5 min | Build changes |

## Development Workflow

### Theme Development (Fast)
```bash
docker compose up --watch
# Edit themes/src/main/resources/theme/usai/login/login.ftl
# Refresh browser → See changes instantly
```

### Extension Development (Slow)
```bash
docker compose up --watch
# Edit keycloak-login.gov-integration/src/main/java/...
# Wait for rebuild → Test changes
```

## Troubleshooting

```bash
# Check container status
docker compose ps

# View logs
docker compose logs keycloak

# Restart specific service
docker compose restart keycloak

# Force rebuild
docker compose up --build --watch
```

## Performance Tips

- Use **sync** for rapid UI iteration
- Use **rebuild** for code changes
- Monitor system resources during rebuilds
- Keep `.dockerignore` optimized
