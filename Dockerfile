FROM ros:melodic-perception

SHELL [ "/bin/bash", "-c" ]

# install depending packages (install moveit! algorithms on the workspace side, since moveit-commander loads it from the workspace)
RUN apt-get update && \
    apt-get install -y git ros-$ROS_DISTRO-moveit ros-$ROS_DISTRO-moveit-commander ros-$ROS_DISTRO-move-base-msgs ros-$ROS_DISTRO-ros-numpy ros-$ROS_DISTRO-geometry && \
    apt-get clean

# install bio_ik
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    mkdir -p /bio_ik_ws/src && \
    cd /bio_ik_ws/src && \
    catkin_init_workspace && \
    git clone --depth=1 https://github.com/TAMS-Group/bio_ik.git && \
    cd .. && \
    catkin_make install -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/ros/$ROS_DISTRO -DCATKIN_ENABLE_TESTING=0 && \
    cd / && rm -r /bio_ik_ws

# create workspace folder
RUN mkdir -p /workspace/src

# copy our algorithm to workspace folder
ADD . /workspace/src

# install dependencies defined in package.xml
RUN cd /workspace && /ros_entrypoint.sh rosdep install --from-paths src --ignore-src -r -y

#My code
RUN apt install -y wget curl git python-pip python3-pip

#RUN mkdir -p /workspace/catkin_ws/src
RUN git clone https://github.com/ARTenshi/realWRS2020.git /workspace/src/wrs2020

RUN chmod +x /workspace/src/wrs2020/install.sh
RUN sh /workspace/src/wrs2020/install.sh > /dev/null

RUN chmod +x /workspace/src/wrs2020/install-opencv.sh
RUN sh /workspace/src/wrs2020/install-opencv.sh > /dev/null

RUN chmod +x /workspace/src/wrs2020/install-darknet.sh
RUN sh /workspace/src/wrs2020/install-darknet.sh > /dev/null

# compile and install our algorithm
RUN cd /workspace && /ros_entrypoint.sh catkin_make --pkg hri_msgs  > /dev/null
RUN cd /workspace && /ros_entrypoint.sh catkin_make install -DCMAKE_INSTALL_PREFIX=/opt/ros/$ROS_DISTRO > /dev/null
RUN source /workspace/devel/setup.bash

RUN apt-get -y install tree > /dev/null
RUN tree -d /workspace > /dev/null

RUN /bin/bash -c "source /workspace/devel/setup.bash && \
                  echo 'source /workspace/devel/setup.bash' >> ~/.bashrc && \
                  export ROS_PACKAGE_PATH=/workspace/src:$ROS_PACKAGE_PATH"

#RUN echo $ROS_PACKAGE_PATH
ENV ROS_PACKAGE_PATH=/workspace/src:/opt/ros/melodic/share
#RUN /bin/bash -c '. /workspace/devel/setup.bash; roslaunch wrs_challenge run.launch'
RUN echo $ROS_PACKAGE_PATH 

#CMD roslaunch wrs_challenge run.launch
RUN /bin/bash -c '. /workspace/devel/setup.bash; roslaunch wrs_challenge run.launch' 
