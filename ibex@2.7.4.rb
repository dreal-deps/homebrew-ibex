class IbexAT274 < Formula
  desc "C++ library for constraint processing over real numbers"
  homepage "https://github.com/ibex-team/ibex-lib"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.7.4.tar.gz"
  revision 8
  sha256 "60c8248fe4669f8634ba3ea5190d06f740215b8f0170bf67bfb41705fa3a5a4c"

  bottle do
    root_url "https://dl.bintray.com/dreal/homebrew-ibex"
    cellar :any
    sha256 "dbc9c054f3964fdb2fe7d4676e52becd2def1a0b0bb617e682a1b036519f97a6" => :high_sierra
    sha256 "822a999a5cbd0f7162d7f3b519b15b1f6d18df57c7dc503ed59ea4fea3230599" => :mojave
    sha256 "4000c806c748acd2579a4cbf03284c941b59746f9b216eb11391dfe9de6e9400" => :catalina    
  end

  keg_only :versioned_formula

  depends_on "pkg-config" => [:build, :test]
  depends_on "clp"

  def install
    ENV.cxx11

    # Reported 9 Oct 2017 https://github.com/ibex-team/ibex-lib/issues/286
    ENV.deparallelize
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --with-optim
      --with-solver
      --with-affine-extended
      --interval-lib=filib
      --lp-lib=clp
      --clp-path=#{Formula["clp"].opt_prefix}
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
    ENV.cxx11
    cp_r (pkgshare/"examples").children, testpath

    # so that pkg-config can remain a build-time only dependency
    inreplace %w[makefile slam/makefile] do |s|
      s.gsub! /CXXFLAGS.*pkg-config --cflags ibex./,
              "CXXFLAGS := -I#{include} -I#{include}/ibex "\
                          "-I#{include}/ibex/3rd "\
                          "`PKG_CONFIG_PATH=#{Formula["clp"].opt_lib}/pkgconfig pkg-config --cflags clp`"
      s.gsub! /LIBS.*pkg-config --libs  ibex./,
              "LIBS := -L#{lib} -libex "\
              "`PKG_CONFIG_PATH=#{Formula["clp"].opt_lib}/pkgconfig pkg-config --libs clp`"
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
