#!/bin/bash

LVLM=false
for arg in "$@"; do
  [[ "$arg" == "--lvlm" ]] && LVLM=true
done

SESSION="raven"
RAVEN="$HOME/RAVEN"

if ! command -v tmux &>/dev/null; then
  echo "tmux is required but not installed. Install with: sudo apt install tmux"
  exit 1
fi

# Kill any existing session cleanly
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Window 1: AirStack + Isaac Sim
tmux new-session -d -s "$SESSION" -n "airstack"
tmux send-keys -t "$SESSION:airstack" "cd $RAVEN/AirStack && airstack up" Enter

# Window 2: RayFronts — start container and run mapping server directly (no manual shell step)
tmux new-window -t "$SESSION" -n "rayfronts"
tmux send-keys -t "$SESSION:rayfronts" "docker run -it --rm --name rayfronts_container --gpus all --network host --ipc host --privileged --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=all -e ROS_DOMAIN_ID=1 -v $RAVEN/RayFronts:/workspace/RayFronts -w /workspace/RayFronts rayfronts:desktop bash -i /workspace/RayFronts/run_mapping_server_rosnode.sh" Enter

# Window 3: Input prompt — wait for container to be ready, then exec in
tmux new-window -t "$SESSION" -n "input"
tmux send-keys -t "$SESSION:input" "echo 'Waiting for rayfronts_container...' && until docker exec rayfronts_container true 2>/dev/null; do sleep 1; done && docker exec -it rayfronts_container bash -i -c 'cd /workspace/RayFronts && python3 input_prompt.py'" Enter

# Window 4 (optional): LVLM
if $LVLM; then
  tmux new-window -t "$SESSION" -n "lvlm"
  tmux send-keys -t "$SESSION:lvlm" "docker run -it --rm --name lvlm_container --gpus all --network host --ipc host --privileged --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=all -e ROS_DOMAIN_ID=1 -v $RAVEN/LVLM:/app -v $HOME/.cache/huggingface:/root/.cache/huggingface lvlm:latest" Enter
fi

# Stop window — pre-loaded, user just hits Enter when ready to shut down
tmux new-window -t "$SESSION" -n "stop"
tmux send-keys -t "$SESSION:stop" "$RAVEN/stop_raven.sh"

tmux select-window -t "$SESSION:input"
tmux attach -t "$SESSION"
