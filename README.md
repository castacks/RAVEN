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

### Starting AirStack

In one terminal, start the AirStack with IsaacSim:

    cd ~/RAVEN/AirStack
    xhost + (This is needed only when you rebooted your computer)
    airstack up

This will start Isaac-Sim, RViz and RQT-GUI.

First, click the play button in Isaac Sim. 

Then hit the `Arm and Takeoff` button on the RQT-GUI. The robot will start taking off. 

(If you click `Fixed Trajectory` and `Publish` buttons, the robot will fly according to the predefined trajectory on the right configurations. We will not use this for RAVEN.)

Hit the `Global Plan` button. The robot will fly following a global waypoint plan. By default, AirStack generates random walk plans. For our purpose, RayFronts will continuously generate a semantic global plan and will overwrite it. 

To shut down the AirStack containers and remove them:

    airstack down


#### Trying different environments

By default, the robot will launch `Fire Academy` scene. If you want to try different scenes, find the `.env` file in `~/RAVEN/AirStack`, and modify the `ISAAC_SIM_SCRIPT_NAME` to different options. We are currently supporting: 

    FireAcademy_Launch.py
    RetroNeighborhood_Launch.py
    AbandonedFactory_Launch.py
    ConstructionSite_Launch.py

Make sure you downloaded these scenes during the setup. All scenes should be inside `~/RAVEN/AirStack/scenes`. 

### Starting RayFronts

On another terminal, start the RayFronts docker container:

    cd ~/RAVEN/RayFronts
    ./run_docker.sh

Then, inside the RayFronts docker container, 

    ./mapping_server_rosnode.sh
