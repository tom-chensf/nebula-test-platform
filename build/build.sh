#!/usr/bin/env bash
#
#  Package nebula as zip package
#
# introduce the args
#   -v: The version of package, default value is the timestamp
#   -o: Package to one or multi packages, `ON` means one package, `OFF` means multi packages, default value is `ON`
#   -r: Whether to strip the package, default value is `FALSE`
#
# usage: ./build.sh -w <workdir> -g <nebula_graph_repo> -s <nebula_storage_repo> -c <nebula_common_repo>  -v <version> -o <ON/OFF> -r <TRUE/FALSE> -b <BRANCH> -d <enablesanitizer> -t <build_type>"
#

set -x
set -e
nebula_graph_repo='https://github.com/vesoft-inc/nebula-graph.git'
nebula_storage_repo='https://github.com/vesoft-inc/nebula-storage.git'
nebula_common_repo='https://github.com/vesoft-inc/nebula-common.git'


version=""
package_one=ON
strip_enable="FALSE"
usage="Usage: ${0} -w <workdir> -g <nebula_graph_repo> -s <nebula_storage_repo> -c <nebula_common_repo>  -v <version> -o <ON/OFF> -r <TRUE/FALSE> -b <BRANCH> -d <enablesanitizer> -t <build_type>"

workdir=$(readlink -f "$(dirname "$0")")
enablesanitizer="OFF"
static_sanitizer="OFF"
build_type="Release"
branch="master"

while getopts w:g:s:c:v:o:r:b:d:t: opt;
do
    case $opt in
        w)
            workdir=$OPTARG
            ;;
        g)
            nebula_graph_repo=$OPTARG
            ;;
        s)
            nebula_storage_repo=$OPTARG
            ;;
        c)
            nebula_common_repo=$OPTARG
            ;;
        v)
            version=$OPTARG
            ;;
        o)
            package_one=$OPTARG
            ;;
        r)
            strip_enable=$OPTARG
            ;;
        b)
            branch=$OPTARG
            ;;
        d)
            enablesanitizer="ON"
            if [ "$OPTARG" == "static" ]; then
                static_sanitizer="ON"
            fi
            build_type="RelWithDebInfo"
            ;;
        t)
            build_type=$OPTARG
            ;;
        ?)
            echo "Invalid option, use default arguments"
            ;;
    esac
done


if [ ! -d $workdir ];then
   mkdir -p $workdir
fi


project_dir=${workdir}/nebula-graph

if [ -d $project_dir ];then
   rm -rf ${project_dir}
fi

pushd ${workdir}

git clone ${nebula_graph_repo} -b ${branch}

if [ $? != 0 ]; then
    echo "git clone" ${nebula_graph_repo} "failed!"
    exit -1
fi

popd

build_dir=${project_dir}/build

[[ -z $version ]] && version=`date +%Y%m%d_%H%M%S_%N |cut -b1-20`


if [[ $strip_enable != TRUE ]] && [[ $strip_enable != FALSE ]]; then
    echo "strip enable is wrong, exit"
    echo ${usage}
    exit -1
fi

echo "current version is [ $version ], strip enable is [$strip_enable], enablesanitizer is [$enablesanitizer], static_sanitizer is [$static_sanitizer]"

# args: <version>
function build {
    version=$1
    san=$2
    ssan=$3
    build_type=$4
    branch=$5
    modules_dir=${project_dir}/modules
    if [[ -d $build_dir ]]; then
        rm -rf ${build_dir}/*
    else
        mkdir ${build_dir}
    fi

    if [[ -d $modules_dir ]]; then
        rm -rf ${modules_dir}/*
    else
        mkdir ${modules_dir}
    fi

    pushd ${build_dir}

    cmake -DCMAKE_BUILD_TYPE=${build_type} \
          -DNEBULA_BUILD_VERSION=${version} \
          -DENABLE_ASAN=${san} \
          -DENABLE_UBSAN=${san} \
          -DENABLE_STATIC_ASAN=${ssan} \
          -DENABLE_STATIC_UBSAN=${ssan} \
          -DCMAKE_INSTALL_PREFIX=/ \
          -DNEBULA_COMMON_REPO_URL=${nebula_common_repo} \
          -DNEBULA_STORAGE_REPO_URL=${nebula_storage_repo} \
          -DNEBULA_COMMON_REPO_TAG=${branch} \
          -DNEBULA_STORAGE_REPO_TAG=${branch} \
          -DENABLE_TESTING=OFF \
          -DENABLE_BUILD_STORAGE=ON \
          -DENABLE_PACK_ONE=${package_one} \
          ..
    if !( make -j25); then
        echo ">>> build nebula failed <<<"
        exit -1
    fi

    popd
}

# args: <strip_enable>
function package {
    package_dir=${build_dir}/package/
    if [[ -d $package_dir ]]; then
        rm -rf ${package_dir}/*
    else
        mkdir ${package_dir}
    fi
    pushd ${package_dir}
    cmake \
        -DNEBULA_BUILD_VERSION=${version} \
        -DENABLE_PACK_ONE=${package_one} \
        -DCMAKE_INSTALL_PREFIX=/ \
        ../../package/
    strip_enable=$1

    args=""
    [[ $strip_enable == TRUE ]] && args="-D CPACK_STRIP_FILES=TRUE -D CPACK_RPM_SPEC_MORE_DEFINE="

    sys_ver=""
    pType="TGZ"
#    pType="ZIP"
    if [[ -f "/etc/redhat-release" ]]; then
        sys_name=`cat /etc/redhat-release | cut -d ' ' -f1`
        if [[ ${sys_name} == "CentOS" ]]; then
            sys_ver=`cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1`
            sys_ver=.el${sys_ver}.x86_64
        elif [[ ${sys_name} == "Fedora" ]]; then
            sys_ver=`cat /etc/redhat-release | cut -d ' ' -f3`
            sys_ver=.fc${sys_ver}.x86_64
        fi
    elif [[ -f "/etc/lsb-release" ]]; then
        sys_ver=`cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d "=" -f 2 | sed 's/\.//'`
        sys_ver=.ubuntu${sys_ver}.amd64
    fi

    if !( cpack -G ${pType} --verbose $args ); then
        echo ">>> package nebula failed <<<"
        exit -1
    else
        # rename package file
        pkg_names=`ls | grep nebula | grep ${version}`
        outputDir=$build_dir/cpack_output
        mkdir -p ${outputDir}
        for pkg_name in ${pkg_names[@]};
        do
            new_pkg_name=${pkg_name/\-Linux/${sys_ver}}
            mv ${pkg_name} ${outputDir}/${new_pkg_name}
            echo "####### taget package file is ${outputDir}/${new_pkg_name}"
        done
    fi
    popd
}


# The main
build $version $enablesanitizer $static_sanitizer $build_type $branch
package $strip_enable
exit 0
