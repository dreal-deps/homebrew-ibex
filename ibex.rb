class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.4.tar.gz"
  sha256 "f40cc010b9ebe3139641428312cdbbff2f48eb4a6c768c731b2ca9e86ea5ddad"
  head "https://github.com/ibex-team/ibex-lib.git"

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    cellar :any
     sha256 "3f1645403851e52c5ee04ab22be58898815acddacc33ee480b519f6b162d6c97" => :el_capitan
     sha256 "57648bde1bfa21d9ddc6105eedf0884f3f982f6850ee10459f6e935973fcff85" => :sierra
     sha256 "4b21696f5ea673786b1288a140dcc3b6ee29db9024c983888e2735ec96e953ed" => :high_sierra
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "dreal-deps/coinor/clp" => :build

  def install
    ENV.cxx11
    ENV.append "CXXFLAGS", "-std=c++11"
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

    pkgshare.install %w[examples]
    (pkgshare/"examples/symb01.txt").write <<-EOS.undent
      function f(x)
        return ((2*x,-x);(-x,3*x));
      end
    EOS
  end

  test do
    cp_r (pkgshare/"examples").children, testpath
    cp pkgshare/"benchs/cyclohexan3D.bch", testpath/"c3D.bch"

    # so that pkg-config can remain a build-time only dependency
    inreplace %w[makefile slam/makefile] do |s|
      s.gsub! /CXXFLAGS.*pkg-config --cflags ibex./,
              "CXXFLAGS := -I#{include} -I#{include}/ibex "\
                          "-I#{include}/ibex/3rd/coin -I#{include}/ibex/3rd"
      s.gsub! /LIBS.*pkg-config --libs  ibex./, "LIBS := -L#{lib} -libex"
    end

    system "make", "ctc01", "ctc02", "symb01", "solver01", "solver02"
    system "make", "-C", "slam", "slam1", "slam2", "slam3"
    %w[ctc01 ctc02 symb01].each { |a| system "./#{a}" }
    %w[solver01 solver02].each { |a| system "./#{a}", "c3D.bch", "1e-05", "10" }
    %w[slam1 slam2 slam3].each { |a| system "./slam/#{a}" }
  end
end
