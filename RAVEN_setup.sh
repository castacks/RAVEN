#!/bin/bash

# Move scenes folder into AirStack
if [ -d "./scenes" ]; then
	mv ./scenes ./AirStack/
fi

# Move all .py files from scenes to AirStack/simulation/isaac-sim/launch_scripts
for f in ./AirStack/scenes/*.py; do
	if [ -f "$f" ]; then
		mv "$f" ./AirStack/simulation/isaac-sim/launch_scripts/
	fi
done


# Update .env file with required variables
ENV_FILE="./AirStack/.env"
if [ -f "$ENV_FILE" ]; then
    sed -i 's|^ISAAC_SIM_USE_STANDALONE=.*$|ISAAC_SIM_USE_STANDALONE="true"|' "$ENV_FILE"
    sed -i 's|^ISAAC_SIM_SCRIPT_NAME=.*$|ISAAC_SIM_SCRIPT_NAME="AbandonedFactory_launch.py"|' "$ENV_FILE"
fi