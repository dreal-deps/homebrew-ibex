class IbexAT274 < Formula
  desc "C++ library for constraint processing over real numbers"
  homepage "https://github.com/ibex-team/ibex-lib"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.7.4.tar.gz"
  revision 2
  sha256 "0820952ec576e2d17701d47e77998fcbed0c90ba6b721926d81065303936550a"

  bottle do
    root_url "https://dl.bintray.com/dreal/homebrew-ibex"
    cellar :any
    sha256 "5f4d08a91fcab4d478116b36f060f58e4a840c7ee076ad46569757eaeb36def8" => :sierra
    sha256 "1d14383ad1a94d232b166cc711bb5b01dbc70e77c2ddd0f4c8b1a6a380b466a2" => :high_sierra
    sha256 "8b67a83a01415b76d621e763f32214ecd0c61ff60c1a36d77c5204e78ec3cc04" => :mojave
  end

  keg_only :versioned_formula

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
