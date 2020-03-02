#!/bin/bash

pushd ${HOME}/MagicMirror

DISPLAY=:0 nohup npm start &

popd
