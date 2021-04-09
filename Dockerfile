ARG PLAT=manylinux2014_x86_64
FROM quay.io/pypa/${PLAT} AS buildenv

ENV USE_BAZEL_VERSION=4.0.0
RUN curl -L "https://github.com/bazelbuild/bazelisk/releases/download/v1.7.5/bazelisk-linux-amd64" -o /usr/local/bin/bazel \
      && chmod +x /usr/local/bin/bazel \
      && bazel version

ARG RE2_GIT_TAG=72f110e82ccf3a9ae1c9418bfb447c3ba1cf95c2
RUN mkdir /src \
      && cd /src \
      && curl -L "https://github.com/google/re2/archive/${RE2_GIT_TAG}.zip" -o re2.zip \
      && unzip re2.zip \
      && mv "re2-$RE2_GIT_TAG" re2

COPY hack-setuptools/ /hack-setuptools/

WORKDIR /src/re2

ARG PYTHON_TAG

ENV PATH=/opt/python/${PYTHON_TAG}/bin:/opt/rh/devtoolset-9/root/bin/:/usr/local/bin:/usr/bin:/bin

# https://pybind11.readthedocs.io/en/stable/installing.html
RUN python -mpip install pybind11[global] \
      && ln -s /opt/python/${PYTHON_TAG}/include/pybind11 /usr/include/

COPY toolchains/BUILD.${PYTHON_TAG} /src/re2/toolchains/BUILD
RUN echo 'register_toolchains("//toolchains:my_py_toolchain")' >> WORKSPACE \
      && sed -ie 's/py3_runtime.interpreter, //' python/py_extension.bzl \
      && sed -ie 's/py3_runtime.interpreter.path/py3_runtime.interpreter_path/' python/py_extension.bzl \
      && bazel build --compilation_mode=opt //python:re2

ARG PYTHON_MODULE_NAME="built-google-re2"
ARG PYTHON_MODULE_VERSION="0.0.7.20210224100510"
# Make "cc" and "c++" simply copy the already-compiled .so to the right place
ENV PATH=/hack-setuptools:/opt/python/${PYTHON_TAG}/bin:/usr/local/bin:/usr/bin:/bin
RUN cd python \
      && sed -ie "s/name='google-re2'/name='${PYTHON_MODULE_NAME}'/" setup.py \
      && sed -ie "s/version='.*'/version='${PYTHON_MODULE_VERSION}'/" setup.py \
      && python setup.py bdist_wheel \
      && auditwheel repair --strip dist/*.whl

# Test!
RUN cd /tmp \
      && python -mpip install absl-py /src/re2/python/wheelhouse/*.whl \
      && python /src/re2/python/re2_test.py
