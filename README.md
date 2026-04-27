<p align="center">
<h1 align="center">RAVEN: Resilient Aerial Navigation via Open-Set Semantic Memory and Behavior Adaptation</h1>
<h3 class="is-size-5 has-text-weight-bold" style="color: orange;" align="center">
    IEEE International Conference on Robotics and Automation (ICRA) 2026
</h3>
<p align="center">
    <a href="https://seungchan-kim.github.io" target="_blank"><strong>Seungchan Kim</strong></a>
    ·
    <a href="https://oasisartisan.github.io" target="_blank"><strong>Omar Alama</strong></a>
    ·
    <a href="https://scholar.google.com/citations?user=91gM0vQAAAAJ&hl=en&oi=ao"><strong>Dmytro Kurdydyk</strong></a>
    ·
    <a href="https://theairlab.org/team/johnk/"><strong>John Keller</strong></a>
    <br>
    <a href="https://nik-v9.github.io/" target="_blank"><strong>Nikhil Keetha</strong></a>
    ·
    <a href="https://theairlab.org/team/wenshan/" target="_blank"><strong>Wenshan Wang</strong></a>
    ·
    <a href="https://talkingtorobots.com/yonatanbisk.html" target="_blank"><strong>Yonatan Bisk</strong></a>
    ·
    <a href="https://theairlab.org/team/sebastian/" target="_blank"><strong>Sebastian Scherer</strong></a>
    <br>
  </p>
</p>
  <h3 align="center"><a href="https://arxiv.org/pdf/2509.23563">Paper</a> | <a href="https://raven-semantic.github.io/">Project Page</a> | <a href="https://youtu.be/slLuZv3-zIs">Video</a></h3>
  <div align="center"></div>

## Warning
**🚧 Work in Progress**
- This repository is under active development. The code is not yet ready for general use. We plan to release a stable version with full documentation and instructions soon. For questions, please open an issue or check back later for updates.

## News/Release
- 01/31/2026: RAVEN was accepted to IEEE ICRA 2026!
- 10/25/2025: RAVEN was presented at IROS 2025 Active Perception Workshop, and received Outstanding Best Paper Award Finalist!
- 09/28/2025: arXiv paper is uploaded. Stay tuned for code release!

## Understanding code pipeline structure

RayFronts serves as a perception and representation backbone of RAVEN. 

AirStack serves as an aerial robot autonomy stack, which supports interface for Isaac Sim, and handles sensors, global & local planning, collision avoidance. 


    +-------------+  Interface    +-------------------+    Sensor Topics    +-------------------+
    |  Isaac Sim  | ----------->  |     AirStack      | ------------------> |     RayFronts     |
    | Simulation  |               |  Autonomy Stack   |                     | Perception & Map  |
    +-------------+               |-------------------|                     |-------------------|
                                  | - Sim interface   |                     | - 3D Mapping      |
                                  | - Sensor drivers  |                     | - Representation  |
                                  | - Global planner  | <-------------------| - Semantic logic  |
                                  | - Local planner   |   Global Waypoints  | - Behavior Tree   |
                                  | - Collision avoid |                     |                   |
                                  +-------------------+                     +-------------------+ 

## Setup

First, clone this repository.

    git clone --recurse-submodules https://github.com/castacks/RAVEN.git
    cd RAVEN
    git checkout main
    git submodule update --init --recursive

Next, you should set up a docker image for RayFronts. Please follow the instructions in: [RayFronts Setup](https://github.com/seungchan-kim/RayFronts/blob/raven/README.md).

Now, for AirStack setup, please follow the instructions in: [AirStack Setup](https://github.com/castacks/AirStack/blob/raven/docs/README.md).

After setting up AirStack, download scenes: 

    cd ~/RAVEN/AirStack/scenes
    ./download_scenes.sh

## Run RAVEN

### Starting AirStack (Terminal 1)

In one terminal, start the AirStack with IsaacSim:

    cd ~/RAVEN/AirStack
    xhost + (This is needed only when you rebooted your computer)
    airstack up

An alternative command to `airstack up` is `docker compose up -d`.

This will start Isaac-Sim, RViz and RQT-GUI.

First, click the play button in Isaac Sim. 

Then hit the `Arm and Takeoff` button on the RQT-GUI. The robot will start taking off. 

(If you click `Fixed Trajectory` and `Publish` buttons, the robot will fly according to the predefined trajectory on the right configurations. We will not use this for RAVEN.)

Hit the `Global Plan` button. The robot will fly following a global waypoint plan. By default, AirStack generates random walk plans. For our purpose, RayFronts will continuously generate a semantic global plan and will overwrite it. 

To shut down the AirStack containers and remove them:

    airstack down

, or equivalently, `docker compose down`. 

### Starting RayFronts (Terminal 2)

On another terminal, start the RayFronts docker container:

    cd ~/RAVEN/RayFronts
    ./run_docker.sh

Then, inside the RayFronts docker container, 

    ./run_mapping_server_rosnode.sh

#### Checking if RayFronts mapper is working:

You will see the following log messages (make sure to press the Play button in Isaac Sim):  

    [rayfronts.datasets.ros][INFO] - Waiting for intrinsics to be published..
    [rayfronts.datasets.ros][INFO] - Loaded intrinsics:
    ....
    [rayfronts.datasets.ros][INFO] - Ros2Subscriber initialized successfully.
If intrinsics is not loaded, check the [intrinsics topic in the configuration file](https://github.com/seungchan-kim/RayFronts/blob/cd5f9abfc773ed12e3be0697434cb1c25af7820c/rayfronts/configs/dataset/ros2isaacsim.yaml#L17). 

If this is your first time running the command, pretrained models (e.g., radio-v2.5-l_half.pth.tar, open_clip_model.safetensors) will be automatically downloaded from external sources such as Torch Hub and Hugging Face. To avoid re-downloading on every fresh container startup, we recommend caching these files in the Docker image. For example, 

    docker commit <container_id> rayfronts:desktop

This will cache the pretrained models inside the existing rayfronts Docker image. 

### Miscellaneous

#### Debugging running containers

While running AirStack, you may want to inspect what is happening inside each Docker container. To enter the robot container:

    docker exec -it airstack-robot-1 bash
To enter the Isaac Sim container: 

    docker exec -it isaac-sim bash
Once inside the container, you can attach to the main session using tmux. 

    tmux a
To detach from tmux (without stopping processes): `Ctrl + B then D`. 

Container names may vary depending on your docker-compose setup.  
Use `docker ps` to list running containers.

#### Trying different environments

By default, the robot will launch `Fire Academy` scene. If you want to try different scenes, find the `.env` file in `~/RAVEN/AirStack`, and modify the `ISAAC_SIM_SCRIPT_NAME` to different options. We are currently supporting: 

    FireAcademy_Launch.py
    RetroNeighborhood_Launch.py
    AbandonedFactory_Launch.py
    ConstructionSite_Launch.py

Make sure you downloaded these scenes during the setup. All scenes should be inside `~/RAVEN/AirStack/scenes`. 
