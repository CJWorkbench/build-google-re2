#!/bin/bash

set -ex

for python_tag in cp36-cp36m cp37-cp37m cp38-cp38 cp39-cp39; do
  docker build . --build-arg PYTHON_TAG=$python_tag
  image=$(docker build . -q --build-arg PYTHON_TAG=$python_tag)
  docker run -it --rm -v "$(realpath "$(dirname "$0")/dist")":/dist "$image" \
    sh -c 'cp -v /src/re2/python/wheelhouse/* /dist/'
done
