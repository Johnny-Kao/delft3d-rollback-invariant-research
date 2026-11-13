# Public, credential-free alternative to Deltares' private buildtools image.
# This is a research build attempt, not an official supported toolchain.
FROM intel/hpckit:2024.2.1-0-devel-rockylinux9

USER root

# Intel's optional GPU repository has a TLS certificate issue on current public runners.
# The CPU/Fortran toolchain does not require it.
RUN dnf -y --disablerepo='intel-graphics*' install epel-release \
    && dnf -y --disablerepo='intel-graphics*' install \
    git wget curl tar xz unzip make m4 patch diffutils which procps-ng \
    gcc gcc-c++ gcc-gfortran python3 python3-pip perl \
    autoconf automake libtool pkgconf-pkg-config patchelf \
    && dnf clean all

# Delft3D main requires CMake 4; the public oneAPI image may ship an older version.
RUN curl -fL --retry 3 --connect-timeout 20 \
      https://github.com/Kitware/CMake/releases/download/v4.2.3/cmake-4.2.3-linux-x86_64.sh \
      -o /tmp/cmake-install.sh \
    && sh /tmp/cmake-install.sh --skip-license --prefix=/usr/local \
    && rm /tmp/cmake-install.sh

RUN python3 -m pip install --no-cache-dir 'conan==2.29.0' || \
    (python3 -m pip install --no-cache-dir --break-system-packages 'conan==2.29.0')

RUN printf '\nsource /opt/intel/oneapi/setvars.sh >/dev/null 2>&1\nexport FC=mpiifx\nexport CC=mpiicx\nexport CXX=mpicxx\nexport LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH:-}\nexport PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}\nexport CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH:-}\n' >> /etc/bashrc

RUN bash -lc 'command -v ifx && command -v mpiifx && command -v cmake && command -v conan && cmake --version && conan --version'
