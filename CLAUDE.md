# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Plex Media Server automation project designed to transform a basic Plex server into a fully automated media management system. The project follows a phased approach detailed in `docs/project_tracker.md`.

**Current Status:** Phase 1 - Basic Plex server setup with hardware complete, waiting for storage drive installation.

## Architecture

The repository follows the structure outlined in `docs/proposed_repo_structure.md`:

- `configs/` - Configuration templates for various services (Plex, Sonarr, Radarr, etc.)
- `scripts/` - Automation scripts for setup, maintenance, and utilities
- `templates/` - Reusable configuration templates and folder structures
- `monitoring/` - Health checks and monitoring configurations
- `data/` - Runtime data (gitignored)
- `logs/` - Application logs (gitignored)
- `docs/` - Project documentation and planning

## Development Commands

This project is currently in early planning/setup phase. No build tools, package managers, or test frameworks are configured yet. The main workflow involves:

1. **Setup Scripts** (when created): Scripts in `scripts/setup/` for initial system configuration
2. **Maintenance Scripts** (when created): Scripts in `scripts/maintenance/` for ongoing operations
3. **Configuration Management**: Template files in `configs/` and `templates/`

## Key Project Phases

1. **Phase 1**: Basic Plex server setup with expanded storage
2. **Phase 2**: Research automation tools (Sonarr, Radarr, Prowlarr, etc.)
3. **Phase 3**: Basic automation implementation
4. **Phase 4**: Advanced features and optimization

## Important Files

- `docs/project_tracker.md` - Detailed phase breakdown and task tracking
- `docs/proposed_repo_structure.md` - Repository structure design
- `.gitignore` - Configured to exclude sensitive configs, media files, and runtime data

## Configuration Strategy

- Use template files (`.template` extension) to avoid committing sensitive data
- Separate configuration structure from sensitive values using `.env` files
- Runtime configurations stored in `data/configs/` (gitignored)

## Target Technology Stack

Based on project planning:
- **Media Server**: Plex Media Server
- **Automation**: Sonarr (TV), Radarr (Movies), Prowlarr (Indexers), Bazarr (Subtitles)
- **Download Client**: qBittorrent or SABnzbd
- **Request Management**: Overseerr
- **Monitoring**: Tautulli
- **Orchestration**: Docker Compose (planned)