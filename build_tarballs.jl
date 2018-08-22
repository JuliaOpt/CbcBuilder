# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CbcBuilder"
version = v"2.9.9"

# Collection of sources required to build CbcBuilder
sources = [
    "https://github.com/coin-or/Cbc/archive/releases/2.9.9.tar.gz" =>
    "3760fa9fe24fe3390c8b3d5f03583a62652d9b159aef9b0b609e4948ef1b8f29",

    "https://github.com/ampl/mp/archive/3.1.0.tar.gz" =>
    "587c1a88f4c8f57bef95b58a8586956145417c8039f59b1758365ccc5a309ae9",

    "https://github.com/staticfloat/mp-extra/archive/v3.1.0-2.tar.gz" =>
    "2f227175437f73d9237d3502aea2b4355b136e29054267ec0678a19b91e9236e",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
set -e

cd Cbc-releases-2.9.9/

# Install dependencies with BuildTools except for Data and ASL

wget https://github.com/coin-or-tools/BuildTools/archive/releases/0.8.8.tar.gz
tar -xzvf 0.8.8.tar.gz
mv BuildTools-releases-0.8.8/ BuildTools
cp Dependencies Dependencies.orig
cat > Dependencies.patch <<'END'
--- Dependencies.orig
+++ Dependencies
@@ -1,12 +1,9 @@
 BuildTools  https://projects.coin-or.org/svn/BuildTools/stable/0.8
-ThirdParty/ASL  https://projects.coin-or.org/svn/BuildTools/ThirdParty/ASL/stable/1.3
 ThirdParty/Blas  https://projects.coin-or.org/svn/BuildTools/ThirdParty/Blas/stable/1.4
 ThirdParty/Lapack  https://projects.coin-or.org/svn/BuildTools/ThirdParty/Lapack/stable/1.5
 ThirdParty/Glpk  https://projects.coin-or.org/svn/BuildTools/ThirdParty/Glpk/stable/1.10
 ThirdParty/Metis  https://projects.coin-or.org/svn/BuildTools/ThirdParty/Metis/stable/1.3
 ThirdParty/Mumps  https://projects.coin-or.org/svn/BuildTools/ThirdParty/Mumps/stable/1.5
-Data/Sample  https://projects.coin-or.org/svn/Data/Sample/stable/1.2
-Data/miplib3  https://projects.coin-or.org/svn/Data/miplib3/stable/1.2
 CoinUtils  https://projects.coin-or.org/svn/CoinUtils/stable/2.10/CoinUtils
 Osi  https://projects.coin-or.org/svn/Osi/stable/0.107/Osi
 Clp  https://projects.coin-or.org/svn/Clp/stable/1.16/Clp
END

patch -l Dependencies.orig Dependencies.patch -o Dependencies
BuildTools/get.dependencies.sh fetch --git
for i in {CoinUtils,Clp,Cgl,Osi}; do     mv $i ${i}.old;     mv ${i}.old/${i} $i;  done

# Use staticfloat's cross-compile trick for ASL https://github.com/ampl/mp/issues/115

cd $WORKSPACE/srcdir/mp-3.1.0
rm -rf thirdparty/benchmark
patch -p1 < $WORKSPACE/srcdir/mp-extra-3.1.0-2/no_benchmark.patch
# Build ASL
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix  -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain       -DRUN_HAVE_STD_REGEX=0       -DRUN_HAVE_STEADY_CLOCK=0       ../
# Copy over pregenerated files after building arithchk, so as to fake out cmake,
# because cmake will delete our arith.h
set +e
make arith-h VERBOSE=1
set -e
mkdir -p src/asl
cp -v $WORKSPACE/srcdir/mp-extra-3.1.0-2/expr-info.cc ../src/expr-info.cc
cp -v $WORKSPACE/srcdir/mp-extra-3.1.0-2/arith.h.${target} src/asl/arith.h
# Build and install ASL
make -j${nproc} VERBOSE=1
make install VERBOSE=1

# Fix configure scripts, configure, make and install Cbc
cd ../../Cbc-releases-2.9.9/
update_configure_scripts
mkdir build
cd build/
../configure --prefix=$prefix --disable-pkg-config --with-asl-lib="$prefix/lib/libasl.a" --with-asl-incdir="$prefix/include/asl" --host=${target} --enable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all
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
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

