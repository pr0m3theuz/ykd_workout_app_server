# YKD Server - Sync Infrastructure

![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Couchbase](https://img.shields.io/badge/Couchbase-EA2328?style=for-the-badge&logo=couchbase&logoColor=white)
![License](https://img.shields.io/badge/License-GPLv3-green)

> Backend synchronization infrastructure for YKD workout tracking app. Enables multi-device sync, data backup, and local-first architecture using Couchbase Server and Sync Gateway.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Services](#services)
- [Database Schema](#database-schema)
- [Testing the Setup](#testing-the-setup)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains the Docker-based backend infrastructure for the YKD workout logging app. It provides:

- **Couchbase Server** - NoSQL database for storing workout data
- **Sync Gateway** - Handles synchronization between mobile clients and the server
- **Automated Setup** - Scripts to initialize the cluster, create collections, and configure sync

The backend enables users to:
- Sync workout data across multiple devices
- Back up their training history to the cloud
- Work offline with automatic sync when reconnected
- Maintain data privacy with user-specific channels

## Architecture

```
┌─────────────────┐
│   YKD Mobile    │
│      App        │
└────────┬────────┘
         │ (Couchbase Lite)
         │
         ▼
┌─────────────────┐
│  Sync Gateway   │  (Port 4984)
│   (Community)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Couchbase Server│  (Port 8091)
│   (Community)   │
│                 │
│  Bucket:        │
│  - workouts     │
│                 │
│  Collections:   │
│  - Exercises    │
│  - Workouts     │
│  - Programs     │
│  - etc.         │
└─────────────────┘
```

**Data Flow:**
1. Mobile app uses Couchbase Lite for local storage
2. Changes sync to Sync Gateway via WebSocket/HTTP
3. Sync Gateway replicates to Couchbase Server
4. Other devices pull changes through Sync Gateway

## Prerequisites

- **Docker** (20.10+) and **Docker Compose** (2.0+)
- **Ports available:**
  - 8091-8096: Couchbase Server (Admin UI, API)
  - 11210: Couchbase data port
  - 4984-4986: Sync Gateway (Public, Admin, Metrics)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/pr0m3theuz/workout-app-server.git
cd workout-app-server
```

### 2. Create Docker Volume

```bash
docker volume create couchbase
```

### 3. Start Services

```bash
docker-compose up -d
```

The initialization process will:
- Start Couchbase Server (takes ~10 seconds)
- Initialize the cluster with admin credentials
- Create the "workouts" bucket
- Create 24 collections for different data types
- Set up RBAC user for Sync Gateway
- Start Sync Gateway and connect to Couchbase

### 4. Configure Sync Gateway Database

Once both services are running, configure the Sync Gateway database:

```bash
chmod +x config-sync-gateway-curl.sh
./config-sync-gateway-curl.sh
```

This script:
- Creates the "workouts" database in Sync Gateway
- Configures import filters for each collection
- Creates a test user (`user/password`)
- Brings the database online

### 5. Verify Setup

**Couchbase Server Admin UI:**
```
http://localhost:8091
Username: Administrator
Password: bWHqoG2v3ko3fG5E
```

**Sync Gateway Admin API:**
```bash
# Check database status
curl http://localhost:4985/workouts/

# List users
curl http://localhost:4985/workouts/_user/
```

**Sync Gateway Public API:**
```bash
# Health check
curl http://localhost:4984/
```

## Configuration

### Environment Variables

Key environment variables in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `COUCHBASE_ADMINISTRATOR_USERNAME` | Administrator | Cluster admin username |
| `COUCHBASE_ADMINISTRATOR_PASSWORD` | bWHqoG2v3ko3fG5E | Cluster admin password |
| `COUCHBASE_BUCKET` | workouts | Main bucket name |
| `COUCHBASE_BUCKET_RAMSIZE` | 512 | Bucket RAM quota (MB) |
| `COUCHBASE_RAM_SIZE` | 2048 | Total cluster RAM (MB) |
| `COUCHBASE_INDEX_RAM_SIZE` | 512 | Index service RAM (MB) |
| `COUCHBASE_RBAC_USERNAME` | admin | Sync Gateway user |
| `COUCHBASE_RBAC_PASSWORD` | bWHqoG2v3ko3fG5E | Sync Gateway password |

### Sync Gateway Configuration

The `bootstrap.json` file configures:
- Connection to Couchbase Server
- API endpoints and authentication
- Logging levels and rotation
- TLS settings
- CORS policies

To modify sync configuration, edit `bootstrap.json` and restart:
```bash
docker-compose restart sync-gateway
```

### Security Notes

⚠️ **Default credentials are for development only!** 

For production:
1. Change all passwords in `docker-compose.yml`
2. Update `bootstrap.json` with new credentials
3. Enable TLS/SSL for Sync Gateway
4. Configure proper CORS policies
5. Use environment variables or secrets management

## Services

### Couchbase Server

**Initialization Script:** `couchbase-server/init-cbserver.sh`

Automatically performs:
- Cluster initialization with data, index, query, and eventing services
- Bucket creation with appropriate RAM quota
- Collection creation for all data types
- RBAC user setup for Sync Gateway access

**Admin UI:** http://localhost:8091

### Sync Gateway

**Initialization Script:** `sync-gateway/init-syncgateway.sh`

Waits for Couchbase Server to be ready, then:
- Starts with bootstrap configuration
- Connects to Couchbase Server
- Exposes public (4984), admin (4985), and metrics (4986) APIs

**Configuration:** `sync-gateway/bootstrap.json`

## Database Schema

The "workouts" bucket contains 24 collections:

### Workout Data
- `CompletedWorkouts` - Finished workout sessions
- `CompletedSets` - Individual set performance data
- `CompletedPrograms` - Completed training programs
- `Workout` - Workout templates
- `WorkoutNote` - User notes on workouts

### Exercise Data
- `Exercise` - Exercise definitions
- `ExerciseNote` - Exercise-specific notes
- `MuscleExercise` - Exercise-muscle relationships
- `Equipment` - Equipment types
- `Force` - Force types (push/pull)
- `Mechanic` - Movement mechanics (compound/isolation)
- `Utility` - Exercise utility classification

### Muscle Data
- `Muscle` - Individual muscle definitions
- `MuscleGroup` - Muscle group categorization
- `MuscleRoleFunction` - Muscle roles (target/synergist/stabilizer)

### Program Data
- `Program` - Training program templates
- `ProgramNote` - Program notes
- `Mesocycle` - Training mesocycles/blocks
- `MesocycleNote` - Mesocycle notes
- `Microcycle` - Weekly training cycles
- `MicrocycleNote` - Microcycle notes

### Training Configuration
- `ModernizedLoadRIR` - RIR-based load calculations
- `LoadRepCapacity` - Rep capacity classifications

### User Data
- `Users` - User profiles and settings

Each collection has type-based import filters to ensure documents are routed correctly.

## Testing the Setup

### 1. Create a Test Document

```bash
curl -X POST http://localhost:4984/workouts/ \
  -H "Content-Type: application/json" \
  -u user:password \
  -d '{
    "type": "Exercise",
    "name": "Bench Press",
    "muscleGroup": "Chest"
  }'
```

### 2. Retrieve Documents

```bash
curl http://localhost:4984/workouts/_all_docs?include_docs=true \
  -u user:password
```

### 3. Check Sync Gateway Stats

```bash
curl http://localhost:4985/workouts/_stats
```

### 4. Monitor Logs

```bash
# Couchbase Server logs
docker logs couchbase-server -f

# Sync Gateway logs
docker logs sync-gateway -f
```

## Troubleshooting

### Services Won't Start

**Check Docker resources:**
```bash
docker info | grep Memory
```
Ensure at least 8GB RAM is available.

**Check port conflicts:**
```bash
lsof -i :8091
lsof -i :4984
```

**View service logs:**
```bash
docker-compose logs couchbase-server
docker-compose logs sync-gateway
```

### Sync Gateway Can't Connect to Couchbase

**Check network connectivity:**
```bash
docker exec sync-gateway ping couchbase-server
```

**Verify Couchbase is ready:**
```bash
docker exec couchbase-server couchbase-cli server-info \
  -c localhost -u Administrator -p bWHqoG2v3ko3fG5E
```

### Import Filters Not Working

**Check collection configuration:**
```bash
curl http://localhost:4985/workouts/_config | jq .
```

**Verify document types match filters:**
Documents must have a `type` field matching the collection name.

### Reset Everything

```bash
# Stop and remove containers
docker-compose down

# Remove volume (⚠️ deletes all data)
docker volume rm couchbase

# Recreate and restart
docker volume create couchbase
docker-compose up -d
./config-sync-gateway-curl.sh
```

## Security Considerations

### Development vs Production

This configuration is optimized for **local development**. For production:

1. **Authentication:**
   - Change all default passwords
   - Use strong, unique credentials
   - Enable admin interface authentication on Sync Gateway

2. **Network Security:**
   - Enable TLS on all endpoints
   - Configure proper firewall rules
   - Use reverse proxy (nginx/Traefik) with SSL termination

3. **Data Security:**
   - Enable encryption at rest on Couchbase
   - Use encrypted replication
   - Implement proper backup strategy

4. **Access Control:**
   - Configure user-specific channels in Sync Gateway
   - Implement proper role-based access control (RBAC)
   - Use JWT or session-based authentication

5. **Monitoring:**
   - Enable audit logging
   - Set up monitoring and alerts
   - Regular security updates

## Connecting the Mobile App

To connect the YKD Android app to this backend:

1. **Configure Sync Gateway endpoint:**
   ```kotlin
   val replicatorConfig = ReplicatorConfiguration(
       database = database,
       target = URLEndpoint(URI("ws://localhost:4984/workouts"))
   )
   ```

2. **Add authentication:**
   ```kotlin
   replicatorConfig.authenticator = BasicAuthenticator(
       username = "user",
       password = "password"
   )
   ```

3. **Start replication:**
   ```kotlin
   val replicator = Replicator(replicatorConfig)
   replicator.start()
   ```

For detailed integration, see the main [YKD app repository](https://github.com/pr0m3theuz/workout-app).

## Contributing

Contributions to improve the sync infrastructure are welcome!

### Areas for Improvement

- Add production-ready configuration examples
- Implement automated testing for sync flows
- Add monitoring and alerting setup
- Create backup and restore scripts
- Add Kubernetes deployment manifests
- Implement zero-downtime updates

Please open an issue or pull request in the [main repository](https://github.com/pr0m3theuz/workout-app).

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

---

**Related Projects:**
- [YKD Mobile App](https://github.com/pr0m3theuz/workout-app) - Android workout logging application

*Part of the YKD ecosystem - Local-first workout tracking with multi-device sync.*
