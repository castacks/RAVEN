#!/bin/bash

echo "Stopping RayFronts..."
docker stop rayfronts_container 2>/dev/null || true

echo "Stopping LVLM..."
docker stop lvlm_container 2>/dev/null || true

echo "Stopping AirStack..."
docker compose -f "$HOME/RAVEN/AirStack/docker-compose.yaml" down

echo "Done."
tmux kill-session -t raven
