#!/bin/bash

LVLM=false
ENV_NAME="RetroNeighborhood"
DRONE_X=""; DRONE_Y=""; DRONE_Z=""
DRONE_QX=""; DRONE_QY=""; DRONE_QZ=""; DRONE_QW=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --env)  ENV_NAME="$2"; shift 2;;
    --x)    DRONE_X="$2";  shift 2;;
    --y)    DRONE_Y="$2";  shift 2;;
    --z)    DRONE_Z="$2";  shift 2;;
    --qx)   DRONE_QX="$2"; shift 2;;
    --qy)   DRONE_QY="$2"; shift 2;;
    --qz)   DRONE_QZ="$2"; shift 2;;
    --qw)   DRONE_QW="$2"; shift 2;;
    --lvlm) LVLM=true;     shift;;
    *)      shift;;
  esac
done

case $ENV_NAME in
  FireAcademy)
    DRONE_X=${DRONE_X:-25.7};  DRONE_Y=${DRONE_Y:-11.5};  DRONE_Z=${DRONE_Z:-0.07}
    DRONE_QX=${DRONE_QX:-0.0}; DRONE_QY=${DRONE_QY:-0.0}
    DRONE_QZ=${DRONE_QZ:--0.93}; DRONE_QW=${DRONE_QW:-0.366};;
  ConstructionSite)
    DRONE_X=${DRONE_X:-13.7};  DRONE_Y=${DRONE_Y:--1.2};  DRONE_Z=${DRONE_Z:-0.07}
    DRONE_QX=${DRONE_QX:-0.0}; DRONE_QY=${DRONE_QY:-0.0}
    DRONE_QZ=${DRONE_QZ:-0.0}; DRONE_QW=${DRONE_QW:-1.0};;
  AbandonedFactory)
    DRONE_X=${DRONE_X:-7.57};  DRONE_Y=${DRONE_Y:--5.5};  DRONE_Z=${DRONE_Z:-0.71}
    DRONE_QX=${DRONE_QX:-0.0}; DRONE_QY=${DRONE_QY:-0.0}
    DRONE_QZ=${DRONE_QZ:-0.0}; DRONE_QW=${DRONE_QW:-1.0};;
  *)
    DRONE_X=${DRONE_X:-0.0};   DRONE_Y=${DRONE_Y:-0.0};   DRONE_Z=${DRONE_Z:-0.07}
    DRONE_QX=${DRONE_QX:-0.0}; DRONE_QY=${DRONE_QY:-0.0}
    DRONE_QZ=${DRONE_QZ:-0.0}; DRONE_QW=${DRONE_QW:-1.0};;
esac

ISAAC_SIM_SCRIPT_NAME="${ENV_NAME}_Launch.py"

SESSION="raven"
RAVEN="$HOME/RAVEN"

# Source .env for other AirStack vars, then re-assert CLI values on top
set -a; source "$RAVEN/AirStack/.env"; set +a
export DRONE_X DRONE_Y DRONE_Z DRONE_QX DRONE_QY DRONE_QZ DRONE_QW ISAAC_SIM_SCRIPT_NAME

if ! command -v tmux &>/dev/null; then
  echo "tmux is required but not installed. Install with: sudo apt install tmux"
  exit 1
fi

# Kill any existing session cleanly
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Window 1: AirStack + Isaac Sim
tmux new-session -d -s "$SESSION" -n "airstack"
tmux send-keys -t "$SESSION:airstack" "cd $RAVEN/AirStack && ISAAC_SIM_SCRIPT_NAME=$ISAAC_SIM_SCRIPT_NAME DRONE_X=$DRONE_X DRONE_Y=$DRONE_Y DRONE_Z=$DRONE_Z DRONE_QX=$DRONE_QX DRONE_QY=$DRONE_QY DRONE_QZ=$DRONE_QZ DRONE_QW=$DRONE_QW airstack up" Enter

# Window 2: RayFronts — start container and run mapping server directly (no manual shell step)
tmux new-window -t "$SESSION" -n "rayfronts"
tmux send-keys -t "$SESSION:rayfronts" "docker run -it --rm --name rayfronts_container --gpus all --network host --ipc host --privileged --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=all -e ROS_DOMAIN_ID=1 -e ISAAC_SIM_SCRIPT_NAME=$ISAAC_SIM_SCRIPT_NAME -e DRONE_X=$DRONE_X -e DRONE_Y=$DRONE_Y -e DRONE_Z=$DRONE_Z -e DRONE_QX=$DRONE_QX -e DRONE_QY=$DRONE_QY -e DRONE_QZ=$DRONE_QZ -e DRONE_QW=$DRONE_QW -v $RAVEN/RayFronts:/workspace/RayFronts -w /workspace/RayFronts rayfronts:desktop bash -i /workspace/RayFronts/run_mapping_server_rosnode.sh" Enter

# Window 3: Input prompt — wait for container to be ready, then exec in
tmux new-window -t "$SESSION" -n "input"
tmux send-keys -t "$SESSION:input" "echo 'Waiting for rayfronts_container...' && until docker exec rayfronts_container true 2>/dev/null; do sleep 1; done && docker exec -it rayfronts_container bash -i -c 'cd /workspace/RayFronts && python3 input_prompt.py'" Enter

# Window 4: Annotation visualizer — publishes all ground-truth bboxes to /annotation_bboxes_all
tmux new-window -t "$SESSION" -n "annotation_viz"
tmux send-keys -t "$SESSION:annotation_viz" "echo 'Waiting for rayfronts_container...' && until docker exec rayfronts_container true 2>/dev/null; do sleep 1; done && docker exec -it rayfronts_container bash -i -c 'cd /workspace/RayFronts && python3 annotation_viz.py'" Enter

# Window 5 (optional): LVLM
if $LVLM; then
  tmux new-window -t "$SESSION" -n "lvlm"
  tmux send-keys -t "$SESSION:lvlm" "docker run -it --rm --name lvlm_container --gpus all --network host --ipc host --privileged --runtime=nvidia -e NVIDIA_DRIVER_CAPABILITIES=all -e ROS_DOMAIN_ID=1 -v $RAVEN/LVLM:/app -v $HOME/.cache/huggingface:/root/.cache/huggingface lvlm:latest" Enter
fi

# Stop window — pre-loaded, user just hits Enter when ready to shut down
tmux new-window -t "$SESSION" -n "stop"
tmux send-keys -t "$SESSION:stop" "$RAVEN/stop_raven.sh"

tmux select-window -t "$SESSION:input"
tmux attach -t "$SESSION"
