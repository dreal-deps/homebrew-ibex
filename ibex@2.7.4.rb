class IbexAT274 < Formula
  desc "C++ library for constraint processing over real numbers"
  homepage "https://github.com/ibex-team/ibex-lib"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.7.4.tar.gz"
  revision 3
  sha256 "60c8248fe4669f8634ba3ea5190d06f740215b8f0170bf67bfb41705fa3a5a4c"

  bottle do
    root_url "https://dl.bintray.com/dreal/homebrew-ibex"
    cellar :any
#    sha256 "" => :sierra
#    sha256 "" => :high_sierra
    sha256 "42cad5f61503396540084f203e49fdd763a74a832f2be59591537b108b809cbb" => :mojave
  end

  keg_only :versioned_formula

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "clp@1.17"

  def install
    ENV.cxx11
    ENV.append "CXXFLAGS", "-std=c++11"
    print prefix.to_s
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --with-optim
      --with-solver
      --with-affine-extended
      --interval-lib=filib
      --lp-lib=clp
      --clp-path=#{HOMEBREW_PREFIX}
    ]
    system "./waf", "configure", *args
    system "./waf", "install"

    pkgshare.install %w[examples plugins/solver/benchs]
    (pkgshare/"examples/symb01.txt").write <<~EOS
      function f(x)
        return ((2*x,-x);(-x,3*x));
      end
    EOS
    inreplace "#{share}/pkgconfig/ibex.pc", prefix, opt_prefix
  end

  test do
    cp_r (pkgshare/"examples").children, testpath

    # so that pkg-config can remain a build-time only dependency
    inreplace %w[makefile slam/makefile] do |s|
      s.gsub! /CXXFLAGS.*pkg-config --cflags ibex./,
              "CXXFLAGS := -std=c++11 -I#{include} -I#{include}/ibex "\
                          "-I#{include}/ibex/3rd "\
                          "`pkg-config --cflags clp`"
      s.gsub! /LIBS.*pkg-config --libs  ibex./,
              "LIBS := -L#{lib} -libex "\
              "`pkg-config --libs clp`"
    end

    (1..8).each do |n|
      system "make", "lab#{n}"
      system "./lab#{n}"
    end

    (1..3).each do |n|
      system "make", "-C", "slam", "slam#{n}"
      system "./slam/slam#{n}"
    end
  end
end
