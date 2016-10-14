#!/usr/bin/env bash

SCRIPTNAME=`basename $0`

USAGE="Usage: $SCRIPTNAME architecture:version [architecture:version ...]
    architecture: one of armeabi armeabi-v7a armeabi-v7a-vfp3 armeabi-v7a-neon x86 mips arm64-v8a x86_64 mips64
    version: any numeric version supported by android ndk, e.g. 16 (Jelly Bean) or 21 (Lollipop)"

if [ "$#" == "0" ]; then
    echo "$USAGE"
    exit 1
fi

PATHPREFIX=`dirname $0`
ABSPATH=`cd "$PATHPREFIX"; pwd`
SRCPATH="$ABSPATH/android/src"
DOWNLOADSPATH="$ABSPATH/android/downloads"
TOOLCHAINSPATH="$ABSPATH/android/toolchains"
BUILDPATH="$ABSPATH/android/build"
LIBPATH="$ABSPATH/android/lib"
INCLUDEPATH="$ABSPATH/android/include"
LICENSEPATH="$ABSPATH/android/licenses"

case "$(uname -s)" in
    Darwin)
        OS="OSX"
        ;;
    Linux)
        OS="LINUX"
        ;;
    CYGWIN*|MINGW32*|MSYS*)
        OS="WINDOWS"
        ;;
    *)
        echo "Unrecognized OS, quitting"
        exit 1
esac


if [ ! -d "$SRCPATH" ]; then
    mkdir "$SRCPATH"
    echo "It looks like this is the first time you are running $SCRIPTNAME"
    echo
    echo "This script will need access to the sources of its dependencies"
    echo
    echo "For each dependency, you will have the option to link to the source directory"
    echo "if you already have the source available. $SCRIPTNAME will not make"
    echo "any modifications to your source directories."
    echo
    echo "Otherwise, this script will download the sources it needs."
fi

if [ ! -d "$SRCPATH/android-ndk" ]; then
    echo
    echo "$SCRIPTPATH uses the Android NDK to cross-compile for"
    echo "architectures running on Android. If you already have the NDK it can"
    echo "be helpful to let $SCRIPTNAME use it so that other projects you build"
    echo "with the NDK can include headers and link to the dependencies built here"
    echo
    echo "Enter the path to android-ndk or leave blank to have $SCRIPTNAME download it"
    echo
    echo -n "android-ndk: "
    read -e ANDROIDNDKPATH
    if [ -z "$ANDROIDNDKPATH" ]; then
        mkdir -p "$DOWNLOADSPATH"
        case "$OS" in
            OSX)
                ANDROIDNDKURL="https://dl.google.com/android/repository/android-ndk-r12b-darwin-x86_64.zip"
                ;;
            LINUX)
                ANDROIDNDKURL="https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip"
                ;;
            WINDOWS)
                ANDROIDNDKURL="https://dl.google.com/android/repository/android-ndk-r12b-windows-x86_64.zip"
                ;;
        esac
        echo "Downloading $ANDROIDNDKURL"
        curl --progress-bar -o "$DOWNLOADSPATH/android-ndk.zip" "$ANDROIDNDKURL"
        echo "Unzipping"
        unzip "$DOWNLOADSPATH/android-ndk.zip" -d "$DOWNLOADSPATH" >/dev/null
        mv "$DOWNLOADSPATH/android-ndk-r12b" "$SRCPATH/android-ndk"
    else
        ABSANDROIDNDKPATH=`cd "$ANDROIDNDKPATH"; pwd`
        ln -s "$ABSANDROIDNDKPATH" "$SRCPATH/android-ndk"
    fi
fi

if [ ! -d "$TOOLCHAINSPATH" ]; then
    echo
    echo "$SCRIPTNAME uses the NDK's make-standalone-toolchain to produce full"
    echo "toolchains for each target architecture and Android version"
    echo
    echo "Choose a path where these toolchains should be kept. This path"
    echo "may be handy to know if you intend on using the toolchains after"
    echo "$SCRIPTNAME has run."
    echo
    echo -n "Toolchains root [$SRCPATH/android-ndk/standalone-toolchains]: "
    read -e TOOLCHAINROOT
    if [ -z "$TOOLCHAINROOT" ]; then
        TOOLCHAINROOT="$SRCPATH/android-ndk/standalone-toolchains"
    else
        TOOLCHAINROOT=`cd "$TOOLCHAINROOT"; pwd`
    fi
    ln -s "$TOOLCHAINROOT" "$TOOLCHAINSPATH"
fi

if [ ! -d "$SRCPATH/android-cmake" ]; then
    echo
    echo "$SCRIPTNAME uses android-cmake to provide cross-compile instructions"
    echo "for dependencies that are built with cmake. Additionally, a specific"
    echo "branch and fork of this repo is required as the original is not"
    echo "actively maintained."
    echo
    echo "Cloning https://github.com/chenxiaolong/android-cmake.git branch 'mbp'"
    git clone https://github.com/chenxiaolong/android-cmake.git -b mbp --single-branch "$SRCPATH/android-cmake"
fi

if [ ! -d "$SRCPATH/libcomplex" ]; then
    echo
    echo "Enter the path of the source for libcomplex if present, or leave"
    echo "blank to have $SCRIPTNAME download it"
    echo
    echo -n "libcomplex: "
    read -e COMPLEX
    if [ -z "$COMPLEX" ]; then
        echo "Cloning https://github.com/quiet/libcomplex.git"
        git clone https://github.com/quiet/libcomplex.git "$SRCPATH/libcomplex"
    else
        ABSCOMPLEX=`cd "$COMPLEX"; pwd`
        ln -s "$ABSCOMPLEX" "$SRCPATH/libcomplex"
    fi
fi

if [ ! -d "$SRCPATH/libcorrect" ]; then
    echo
    echo "Enter the path of the source for libcorrect if present, or leave blank"
    echo "to have $SCRIPTNAME download it"
    echo
    echo -n "libcorrect: "
    read -e FEC
    if [ -z "$FEC" ]; then
        echo "Cloning https://github.com/quiet/libcorrect.git"
        git clone https://github.com/quiet/libcorrect.git "$SRCPATH/libcorrect"
    else
        ABSFEC=`cd "$FEC"; pwd`
        ln -s "$ABSFEC" "$SRCPATH/libcorrect"
    fi
fi

if [ ! -d "$SRCPATH/liquid-dsp" ]; then
    echo
    echo "Enter the path of the source for liquid-dsp if present, or leave"
    echo "blank to have $SCRIPTNAME download it"
    echo
    echo -n "liquid-dsp: "
    read -e LIQUID
    if [ -z "$LIQUID" ]; then
        echo "Cloning https://github.com/quiet/liquid-dsp.git branch 'devel'"
        git clone https://github.com/quiet/liquid-dsp.git -b devel --single-branch "$SRCPATH/liquid-dsp"
    else
        ABSLIQUID=`cd "$LIQUID"; pwd`
        ln -s "$ABSLIQUID" "$SRCPATH/liquid-dsp"
    fi
fi

if [ ! -d "$SRCPATH/jansson" ]; then
    echo
    echo "Enter the path of the source for jansson if present, or leave"
    echo "blank to have $SCRIPTNAME download it"
    echo
    echo -n "jansson: "
    read -e JANSSON
    if [ -z "$JANSSON" ]; then
        echo "Cloning https://github.com/akheron/jansson.git"
        git clone https://github.com/akheron/jansson.git "$SRCPATH/jansson"
    else
        ABSJANSSON=`cd "$JANSSON"; pwd`
        ln -s "$ABSJANSSON" "$SRCPATH/jansson"
    fi
fi

if [ ! -d "$SRCPATH/quiet" ]; then
    echo
    echo "Enter the path of the source for quiet if present, or leave"
    echo "blank to have $SCRIPTNAME download it"
    echo
    echo -n "quiet: "
    read -e QUIET
    if [ -z "$QUIET" ]; then
        echo "Cloning https://github.com/quiet/quiet.git"
        git clone https://github.com/quiet/quiet.git "$SRCPATH/quiet"
    else
        ABSQUIET=`cd "$QUIET"; pwd`
        ln -s "$ABSQUIET" "$SRCPATH/quiet"
    fi
fi

if [ ! -d "$SRCPATH/quiet-lwip" ]; then
    echo
    echo "Enter the path of the source for quiet-lwip if present, or leave"
    echo "blank to have $SCRIPTNAME download it"
    echo
    echo -n "quiet-lwip: "
    read -e QUIETLWIP
    if [ -z "$QUIETLWIP" ]; then
        echo "Cloning https://github.com/quiet/quiet-lwip.git"
        git clone https://github.com/quiet/quiet-lwip.git "$SRCPATH/quiet-lwip"
    else
        ABSQUIETLWIP=`cd "$QUIETLWIP"; pwd`
        ln -s "$ABSQUIETLWIP" "$SRCPATH/quiet-lwip"
    fi
fi

while (( "$#" )); do
    IFS=':' read -a target_tuple <<< "$1"
    architecture="${target_tuple[0]}"
    version="${target_tuple[1]}"
    cflags=""
    ldflags=""
    basearch=""
    case "$architecture" in
        armeabi)
            basearch="arm"
            cflags="-march-armv5te -mtune=xscale -msoft-float"
            triple="arm-linux-androideabi"
            ;;
        armeabi-v7a)
            basearch="arm"
            cflags="-march=armv7-a -mfloat-abi=softfp"
            ldflags="-Wl,--fix-cortex-a8"
            triple="arm-linux-androideabi"
            ;;
        armeabi-v7a-vfp3)
            basearch="arm"
            cflags="-mfpu=vfpv3"
            ldflags="-Wl,--fix-cortex-a8"
            triple="arm-linux-androideabi"
            ;;
        armeabi-v7a-neon)
            basearch="arm"
            cflags="-mfpu=neon"
            ldflags="-Wl,--fix-cortex-a8"
            triple="arm-linux-androideabi"
            ;;
        x86)
            basearch="x86"
            triple="i686-linux-android"
            ;;
        mips)
            basearch="mips"
            triple="mipsel-linux-android"
            ;;
        arm64-v8a)
            basearch="arm64"
            cflags="-march=armv8-a"
            ldflags="-fuse-ld=gold"
            triple="aarch64-linux-android"
            ;;
        x86_64)
            basearch="x86_64"
            triple="x86_64-linux-android"
            ;;
        mips64)
            basearch="mips64"
            triple="mips64el-linux-android"
            ;;
        *)
            echo "$USAGE"
            exit 1
            ;;
    esac

    toolchainname="$architecture-$version"

    if [ ! -d "$TOOLCHAINSPATH/$toolchainname" ]; then
        echo "Creating toolchain for $architecture:$version"
        $SRCPATH/android-ndk/build/tools/make_standalone_toolchain.py --arch "$basearch" --api "$version" --install-dir "$TOOLCHAINSPATH/$toolchainname"
        if [ $? -ne 0 ]; then
            echo $USAGE
            exit 1
        fi
    fi

    BINPATH="$TOOLCHAINSPATH/$toolchainname/bin"
    export SYSROOT="$TOOLCHAINSPATH/$toolchainname/sysroot"
    export PATH="$BINPATH:$PATH"
    export CC="$triple-gcc --sysroot $SYSROOT"
    export CXX="$triple-g++ --sysroot $SYSROOT"
    export LD="$triple-ld --sysroot $SYSROOT"
    export AR="$triple-ar"
    export RANLIB="$triple-ranlib"
    export AS="$triple-as"
    #export CXXSTL="$SRCPATH/android-ndk/sources/cxx-stl/gnu-lbstdc++/4.9"
    export ANDROID_STL="c++_static"

    mkdir -p "$BUILDPATH/$toolchainname"

    rm -rf "$BUILDPATH/$toolchainname/libcomplex"
    cp -LR "$SRCPATH/libcomplex" "$BUILDPATH/$toolchainname/libcomplex"
    cd "$BUILDPATH/$toolchainname/libcomplex"
    make clean
    CFLAGS="--prefix=$SYSROOT/usr -fpic $cflags" LDFLAGS="$ldflags" make
    make install

    rm -rf "$BUILDPATH/$toolchainname/libcorrect"
    cp -LR "$SRCPATH/libcorrect" "$BUILDPATH/$toolchainname/libcorrect"
    cd "$BUILDPATH/$toolchainname/libcorrect"
    cp "$SRCPATH/android-cmake/android.toolchain.cmake" .
    cmake -DCMAKE_TOOLCHAIN_FILE="./android.toolchain.cmake" -DANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAINSPATH/$toolchainname" -DCMAKE_BUILD_TYPE=Release -DANDROID_SYSROOT="$SYSROOT" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DANDROID_STL="c++_static" "$SRCPATH/libcorrect" && make && make shim && make install

    rm -rf "$BUILDPATH/$toolchainname/liquid-dsp"
    cp -LR "$SRCPATH/liquid-dsp" "$BUILDPATH/$toolchainname/liquid-dsp"
    cd "$BUILDPATH/$toolchainname/liquid-dsp"
    make clean
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_func_realloc_0_nonnull=yes
    ./configure --host="$triple" --disable-shared CFLAGS="-I$SYSROOT/usr/include -g $cflags" LDFLAGS="-lcomplex -lm $ldflags" --prefix="$SYSROOT/usr" --includedir="$SYSROOT/usr/include"
    make
    make install

    rm -rf "$BUILDPATH/$toolchainname/jansson"
    mkdir -p "$BUILDPATH/$toolchainname/jansson"
    cd "$BUILDPATH/$toolchainname/jansson"
    cp "$SRCPATH/android-cmake/android.toolchain.cmake" .
    cmake -DCMAKE_TOOLCHAIN_FILE="./android.toolchain.cmake" -DANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAINSPATH/$toolchainname" -DCMAKE_BUILD_TYPE=Release -DJANSSON_BUILD_SHARED_LIBS=on -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DANDROID_STL="c++_static" -DCMAKE_SHARED_LINKER_FLAGS="-lm" "$SRCPATH/jansson" && make && make install
    cmake -DCMAKE_TOOLCHAIN_FILE="./android.toolchain.cmake" -DANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAINSPATH/$toolchainname" -DCMAKE_BUILD_TYPE=Release -DJANSSON_BUILD_SHARED_LIBS=off -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DANDROID_STL="c++_static" -DCMAKE_SHARED_LINKER_FLAGS="-lm" "$SRCPATH/jansson" && make && make install

    rm -rf "$BUILDPATH/$toolchainname/quiet"
    mkdir -p "$BUILDPATH/$toolchainname/quiet"
    cd "$BUILDPATH/$toolchainname/quiet"
    cp "$SRCPATH/android-cmake/android.toolchain.cmake" .
    cmake -DCMAKE_TOOLCHAIN_FILE="./android.toolchain.cmake" -DANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAINSPATH/$toolchainname" -DCMAKE_BUILD_TYPE=Release -DANDROID_SYSROOT="$SYSROOT" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DANDROID_STL="c++_static" "$SRCPATH/quiet" && make && make install

    rm -rf "$BUILDPATH/$toolchainname/quiet-lwip"
    mkdir -p "$BUILDPATH/$toolchainname/quiet-lwip"
    cd "$BUILDPATH/$toolchainname/quiet-lwip"
    cp "$SRCPATH/android-cmake/android.toolchain.cmake" .
    cmake -DCMAKE_TOOLCHAIN_FILE="./android.toolchain.cmake" -DANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAINSPATH/$toolchainname" -DCMAKE_BUILD_TYPE=Release -DANDROID_SYSROOT="$SYSROOT" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DANDROID_STL="c++_static" "$SRCPATH/quiet-lwip" && make && make install

    mkdir -p "$LIBPATH/$toolchainname"
    mkdir -p "$INCLUDEPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libcomplex.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libfec.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libliquid.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libjansson.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libquiet.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/lib/libquiet_lwip.so" "$LIBPATH/$toolchainname"
    cp "$SYSROOT/usr/include/complex.h" "$INCLUDEPATH/$toolchainname"
    cp "$SYSROOT/usr/include/fec.h" "$INCLUDEPATH/$toolchainname"
    cp -R "$SYSROOT/usr/include/liquid" "$INCLUDEPATH/$toolchainname"
    cp "$SYSROOT/usr/include/jansson.h" "$INCLUDEPATH/$toolchainname"
    cp "$SYSROOT/usr/include/jansson_config.h" "$INCLUDEPATH/$toolchainname"
    cp "$SYSROOT/usr/include/quiet.h" "$INCLUDEPATH/$toolchainname"
    cp -R "$SYSROOT/usr/include/quiet-lwip" "$INCLUDEPATH/$toolchainname"

    shift
done

mkdir -p "$LICENSEPATH"
cp "$SRCPATH/libcomplex/COPYRIGHT" "$LICENSEPATH/libcomplex"
cp "$SRCPATH/libcorrect/LICENSE" "$LICENSEPATH/libcorrect"
cp "$SRCPATH/liquid-dsp/LICENSE" "$LICENSEPATH/liquid-dsp"
cp "$SRCPATH/jansson/LICENSE" "$LICENSEPATH/jansson"
cp "$SRCPATH/quiet/LICENSE" "$LICENSEPATH/quiet"
cp "$SRCPATH/quiet-lwip/LICENSE" "$LICENSEPATH/quiet-lwip"

echo
echo "Build complete. Built libraries are in $LIBPATH"
echo "and includes in $INCLUDEPATH. Third-party licenses"
echo "are in $LICENSEPATH."
