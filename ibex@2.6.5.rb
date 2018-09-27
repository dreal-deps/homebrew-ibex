class IbexAT265 < Formula
  desc "C++ library for constraint processing over real numbers"
  homepage "https://github.com/ibex-team/ibex-lib"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.5.tar.gz"
  sha256 "e15d00be68952dae29ebe553820ee5d9735a8a76b4e2b40a589980ea9f79d0bc"
  revision 5

  bottle do
    root_url "https://dl.bintray.com/dreal/homebrew-ibex"
    cellar :any
    # sha256 "" => :sierra
    # sha256 "" => :high_sierra
    # sha256 "" => :mojave
  end

  keg_only :versioned_formula

  option :cxx11

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "dreal-deps/coinor/clp"

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
