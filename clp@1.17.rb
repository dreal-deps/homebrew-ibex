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
  url "https://www.coin-or.org/download/pkgsource/Clp/Clp-1.17.2.tgz"
  sha256 "12320e817d9fdbaeef262bd76336002f65418f80ec295f21128acf0e833b283e"

  keg_only :versioned_formula

  depends_on "pkg-config" => :build
  depends_on "gcc"
  depends_on "openblas"

  resource "coin-or-coin-utils" do
    url "https://www.coin-or.org/download/pkgsource/CoinUtils/CoinUtils-2.11.2.tgz"
    sha256 "f27b76617d090fb82fba6229ce165c7acfef5d5d1fff40528c6bad4e55a4477b"
  end

  resource "coin-or-netlib-data" do
    url "https://www.coin-or.org/download/source/Data/Data-Netlib-1.2.7.tgz"
    sha256 "c3cc6abe8313e4c8a0f999281d66d1c6b0ff3f7b60c25133291663e74aac4796"
  end

  resource "coin-or-sample-data" do
    url "https://www.coin-or.org/download/source/Data/Data-Sample-1.2.11.tgz"
    sha256 "7d201dc37098dd1f7d68c24d71ca8083eaaa344ec44bd18799ac6245363f8467"
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
