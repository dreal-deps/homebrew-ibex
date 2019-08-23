# BSD 2-Clause "Simplified" License
#
# Copyright (c) 2019, Homebrew contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

class ClpAT117 < Formula
  desc "Linear programming solver"
  homepage "https://projects.coin-or.org/Clp"
  url "https://github.com/coin-or/Clp/archive/releases/1.17.3.zip"
  sha256 "1878ef4b4efa2408dff5c319ae26c402d742f6a2a71dccd9a50b5f62be130b78"
  revision 1

  bottle do
    root_url "https://dl.bintray.com/dreal/homebrew-ibex"
    cellar :any
    sha256 "de8c59161b6416a0abd1e0dc0e712995ba1e6ae72b27839732b4aed2a6786ac2" => :sierra
    sha256 "13d2c75590a45f8af7453f9329032ccd40c84f231d6e244de95d664133fb40c3" => :high_sierra
    sha256 "d53bc8f5505b57701e60dcabb1747bea7e5f393eca8a381ed1ff8a1318fd66e8" => :mojave
  end
  
  keg_only :versioned_formula

  depends_on "pkg-config" => :build
  depends_on "gcc"
  depends_on "openblas"

  resource "coin-or-coin-utils" do
    url "https://github.com/coin-or/CoinUtils/archive/releases/2.11.2.tar.gz"
    sha256 "30c7f6c84dbb9f6e4fe5bbe4015ed15e2d1402146f8354cfc50c34d8735a49b1"
  end

  resource "coin-or-netlib-data" do
    url "https://github.com/coin-or-tools/Data-Netlib/archive/releases/1.2.6.tar.gz"
    sha256 "fac8b46bdc4b80eeb321ab437812d3bff1f2887c71822d6a26914ac8bfe3628e"
  end

  resource "coin-or-sample-data" do
    url "https://github.com/coin-or-tools/Data-Sample/archive/releases/1.2.11.tar.gz"
    sha256 "888d21a31e93a529eb3743a92f2ba62b94b3eed4ddc44351feb8034a84c71ec5"
  end

  def install
    resource("coin-or-netlib-data").stage do
      args = %W[
        --datadir=#{pkgshare}
        --disable-debug
        --disable-dependency-tracking
        --disable-silent-rules
        --prefix=#{prefix}
      ]
      system "./configure", *args
      system "make"
      system "make", "install"
      rm_f lib/"pkgconfig/coindatanetlib.pc"
    end

    resource("coin-or-sample-data").stage do
      args = %W[
        --datadir=#{pkgshare}
        --disable-debug
        --disable-dependency-tracking
        --disable-silent-rules
        --prefix=#{prefix}
      ]
      system "./configure", *args
      system "make"
      system "make", "install"
      rm_f lib/"pkgconfig/coindatasample.pc"
    end

    resource("coin-or-coin-utils").stage do
      args = [
        "--datadir=#{pkgshare}",
        "--disable-debug",
        "--disable-dependency-tracking",
        "--disable-silent-rules",
        "--prefix=#{prefix}",
        "--includedir=#{include}/clp",
        "--with-sample-datadir=#{pkgshare}/coin/Data/Sample",
        "--with-netlib-datadir=#{pkgshare}/coin/Data/Netlib",
        "--with-blas-incdir=#{Formula["openblas"].opt_include}",
        "--with-blas-lib=-L#{Formula["openblas"].opt_lib} -lopenblas",
        "--with-lapack-incdir=#{Formula["openblas"].opt_include}",
        "--with-lapack-lib=-L#{Formula["openblas"].opt_lib} -lopenblas",
      ]
      system "./configure", *args
      system "make"
      ENV.deparallelize { system "make", "install" }
      rm_f lib/"pkgconfig/coinutils.pc"
    end

    args = [
      "--datadir=#{pkgshare}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--includedir=#{include}/clp",
      "--prefix=#{prefix}",
      "--with-blas-incdir=#{Formula["openblas"].opt_include}",
      "--with-blas-lib=-L#{Formula["openblas"].opt_lib} -lopenblas",
      "--with-coinutils-incdir=#{include}/clp/coin",
      "--with-coinutils-lib=-L#{lib} -lCoinUtils",
      "--with-lapack-incdir=#{Formula["openblas"].opt_include}",
      "--with-lapack-lib=-L#{Formula["openblas"].opt_lib} -lopenblas",
      "--with-netlib-datadir=#{pkgshare}/coin/Data/Netlib",
      "--with-sample-datadir=#{pkgshare}/coin/Data/Sample",
    ]
    system "./configure", *args
    system "make"
    ENV.deparallelize
    system "make", "install"
    inreplace "#{lib}/pkgconfig/clp.pc", "-L#{lib} -lCoinUtils ", "-lCoinUtils"
    inreplace "#{lib}/pkgconfig/clp.pc", "includedir=#{prefix}", "includedir=${prefix}"
    inreplace "#{lib}/pkgconfig/clp.pc", prefix, opt_prefix
  end

  test do
    system bin/"clp", "-import", pkgshare/"coin/Data/Sample/p0033.mps", "-primals"
    (testpath/"test.cpp").write <<~EOS
      #include <ClpSimplex.hpp>
      int main() {
        ClpSimplex model;
        int status = model.readMps("#{pkgshare}/coin/Data/Sample/p0033.mps", true);
        if (status != 0) { return status; }
        status = model.primal();
        return status;
      }
    EOS
    system ENV.cxx, "test.cpp", "-I#{opt_include}/clp/coin", "-L#{opt_lib}", "-lClp", "-lClpSolver", "-lCoinUtils"
    system "./a.out"
  end
end
