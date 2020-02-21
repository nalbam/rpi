#!/bin/bash

sudo apt update
sudo apt upgrade -y

pip3 install cmake
pip3 install face_recognition
pip3 install imutils
pip3 install opencv-python==3.4.6.27
# pip3 install opencv-python-headless
# pip3 install opencv-contrib-python

sudo apt install -y libhdf5-dev libatlas-base-dev libjasper-dev libqtgui4 libqt4-test

# https://github.com/amymcgovern/pyparrot/issues/34
