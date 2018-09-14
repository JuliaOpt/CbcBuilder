# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CbcBuilder"
version = v"2.9.9"

# Collection of sources required to build CbcBuilder
sources = [
    "https://github.com/coin-or/Cbc/archive/releases/2.9.9.tar.gz" =>
    "3760fa9fe24fe3390c8b3d5f03583a62652d9b159aef9b0b609e4948ef1b8f29",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
set -e

cd Cbc-releases-2.9.9/

update_configure_scripts
mkdir build
cd build/
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all --with-glpk-lib="-L${prefix}/lib -lcoinglpk" --with-glpk-incdir="$prefix/include/coin/ThirdParty" --with-lapack="-L${prefix}/lib -lcoinlapack" --with-blas="-L${prefix}/lib -lcoinblas -lgfortran" --with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" --with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin" --with-clp-lib="-L${prefix}/lib -lClp" --with-osi-incdir="$prefix/include/coin" --with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" --with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" --with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl --with-cgl-lib="-L${prefix}/lib -lcgl" --with-cgl-incdir="$prefix/include/cgl"
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libCbcSolver", :libCbcSolver),
    LibraryProduct(prefix, "libCbc", :libCbc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/CglBuilder/releases/download/0.59.10/build_CglBuilder.v0.59.10.jl",
    "https://github.com/juan-pablo-vielma/OsiBuilder/releases/download/v0.107.9/build_OsiBuilder.v0.107.9.jl",
    "https://github.com/juan-pablo-vielma/CoinUtilsBuilder/releases/download/v2.10.14/build_CoinUtilsBuilder.v2.10.14.jl",
    "https://github.com/juan-pablo-vielma/COINGLPKBuilder/releases/download/v1.10.5/build_COINGLPKBuilder.v1.10.5.jl",
    "https://github.com/juan-pablo-vielma/COINMumpsBuilder/releases/download/v1.6.0/build_COINMumpsBuilder.v1.6.0.jl",
    "https://github.com/juan-pablo-vielma/COINMetisBuilder/releases/download/v1.3.5/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/juan-pablo-vielma/ASLBuilder/releases/download/v3.1.0/build_ASLBuilder.v3.1.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

