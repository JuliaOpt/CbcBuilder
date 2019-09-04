# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CbcBuilder"
version = v"2.10.3"

# Collection of sources required to build CbcBuilder
sources = [
    "https://github.com/coin-or/Cbc/archive/releases/2.10.3.tar.gz" =>
    "944c1f717e653aa04f4d6c775aa91d749ab5990d6ee9c3e4f76b9df5bc6e2a8d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
set -e

cd Cbc-releases-2.10.3/

update_configure_scripts
mkdir build
cd build/


## STATIC BUILD START
# Staticly link all dependencies and export only Clp symbols

# force only exporting symbols related to Clp
sed -i~ -e 's|LT_LDFLAGS="-no-undefined"|LT_LDFLAGS="-no-undefined -export-symbols-regex \\"Cbc\\""|g' ../configure
sed -i~ -e 's|LT_LDFLAGS="-no-undefined"|LT_LDFLAGS="-no-undefined -export-symbols-regex \\"Cbc\\""|g' ../Cbc/configure

if [ $target = "x86_64-apple-darwin14" ]; then

 sed -i~ -e "s|~nmedit -s \$output_objdir/\${libname}-symbols.expsym \${lib}| -exported_symbols_list \$output_objdir/\${libname}-symbols.expsym|g" ../configure

../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-cgl-lib="-L${prefix}/lib -lCgl" --with-cgl-incdir="$prefix/include/coin" \
--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas-lib="-L${prefix}/lib -lcoinblas" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack" \
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
--with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin" \
--with-clp-lib="${prefix}/lib/libClp.a ${prefix}/lib/libOsiClp.a" --with-clp-incdir="$prefix/include/coin" \
--with-coindepend-lib="-L${prefix}/lib -lCgl -lOsi ${prefix}/lib/libClp.a -lCoinUtils -lcoinmumps -lcoinmetis -lbz2 -lz -lcoinlapack -lcoinblas" \
--enable-cbc-parallel \
LDFLAGS=-ldl;

elif [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then 

 for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
 done
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-cgl-lib="-L${prefix}/lib -lCgl" --with-cgl-incdir="$prefix/include/coin" \
--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas-lib="-L${prefix}/lib -lcoinblas" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack" \
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
--with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin" \
--with-clp-lib="${prefix}/lib/libClp.a ${prefix}/lib/libOsiClp.a" --with-clp-incdir="$prefix/include/coin" \
--with-coindepend-lib="-L${prefix}/lib -lCgl -lOsi ${prefix}/lib/libClp.a -lcoinmumps -lcoinmetis -lCoinUtils -lcoinlapack -lcoinblas -lgfortran" \
--enable-cbc-parallel

else
  for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
  done
  ../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
  --with-asl-lib="${prefix}/lib/libasl.a" --with-asl-incdir="$prefix/include/asl" \
  --with-blas-lib="${prefix}/lib/libcoinblas.a -lgfortran" \
  --with-lapack-lib="${prefix}/lib/libcoinlapack.a" \
  --with-metis-lib="${prefix}/lib/libcoinmetis.a" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
  --with-mumps-lib="${prefix}/lib/libcoinmumps.a -lgfortran" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
  --with-coinutils-lib="${prefix}/lib/libcoinlapack.a ${prefix}/lib/libcoinblas.a ${prefix}/lib/libCoinUtils.a -lbz2 -lz" --with-coinutils-incdir="$prefix/include/coin" \
  --with-osi-lib="${prefix}/lib/libOsi.a" --with-osi-incdir="$prefix/include/coin" \
  --with-cgl-lib="${prefix}/lib/libCgl.a" --with-cgl-incdir="$prefix/include/coin" \
  --with-clp-lib="${prefix}/lib/libClp.a ${prefix}/lib/libOsiClp.a" --with-clp-incdir="$prefix/include/coin" \
  --with-coindepend-lib="${prefix}/lib/libCgl.a ${prefix}/lib/libOsi.a ${prefix}/lib/libClp.a ${prefix}/lib/libcoinmumps.a ${prefix}/lib/libcoinmetis.a ${prefix}/lib/libCoinUtils.a ${prefix}/lib/libcoinlapack.a ${prefix}/lib/libcoinblas.a -lgfortran" \
  lt_cv_deplibs_check_method=pass_all \
  --enable-cbc-parallel \
  LDFLAGS=-ldl;
fi
## STATIC BUILD END


## DYNAMIC BUILD START
#../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
#--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-cgl-lib="-L${prefix}/lib -lCgl" --with-cgl-incdir="$prefix/include/coin" \
#--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
#--with-blas="-L${prefix}/lib -lcoinblas" \
#--with-lapack="-L${prefix}/lib -lcoinlapack" \
#--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
#--with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
#--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
#--with-osi-lib="-L${prefix}/lib -lOsi"  --with-osi-incdir="$prefix/include/coin" \
#--with-clp-lib="-L${prefix}/lib -lClp -lOsiClp" --with-clp-incdir="$prefix/include/coin" \
#--with-coindepend-lib="-L${prefix}/lib -lCgl -lOsi -lClp -lCoinUtils" \
#--enable-cbc-parallel
## DYNAMIC BUILD END

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
platforms = setdiff(platforms, [Windows(:x86_64, compiler_abi=CompilerABI(:gcc4)), Windows(:i686, compiler_abi=CompilerABI(:gcc4))])
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libCbcSolver", :libcbcsolver),
    LibraryProduct(prefix, "libCbc", :libCbc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/CglBuilder/releases/download/v0.59.10-1-static/build_CglBuilder.v0.59.10.jl",
  #  "https://github.com/JuliaOpt/ClpBuilder/releases/download/v1.16.11-1-static/build_ClpBuilder.v1.16.11.jl",
    "https://github.com/juan-pablo-vielma/OsiBuilder/releases/download/v0.107.9-1-static/build_OsiBuilder.v0.107.9.jl",
    "https://github.com/juan-pablo-vielma/CoinUtilsBuilder/releases/download/v2.10.14-1-static/build_CoinUtilsBuilder.v2.10.14.jl",
    "https://github.com/juan-pablo-vielma/COINMumpsBuilder/releases/download/v1.6.0-1-static/build_COINMumpsBuilder.v1.6.0.jl",
    "https://github.com/juan-pablo-vielma/COINMetisBuilder/releases/download/v1.3.5-1-static/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/juan-pablo-vielma/ASLBuilder/releases/download/v3.1.0-1-static/build_ASLBuilder.v3.1.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
