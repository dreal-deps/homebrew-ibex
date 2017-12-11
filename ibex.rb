class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.3.tar.gz"
  sha256 "2c2c8b048a16ee45f5cc29797f97b8cb0e330be52114212e464835ef44606011"
  head "https://github.com/ibex-team/ibex-lib.git"

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    cellar :any
#    sha256 "d72847e8b2f67f799bb78e6ea65d8743cfdd573ae6728a938108c780362a7631" => :el_capitan
#    sha256 "0db7d5788d51359c60dc2eed57c0d8017c8d9fe93388b566540ca01f82db30f5" => :high_sierra
#    sha256 "e3a6a340acb5e84836fe0862f773d5408e97fc3f1a2bacedb9f61af8f3f14792" => :sierra
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "dreal-deps/coinor/clp"

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
