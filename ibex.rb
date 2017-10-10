class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.5.2.tar.gz"
  sha256 "ef0ad833336f8ac6b1be2a6bb9ad995d103f6964587d7b8b5ec48438bf4fed13"
  head "https://github.com/ibex-team/ibex-lib.git"
  revision 1

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    sha256 "a374948e40655b3e4938a1a8484763c7db454d2b8f30a872b3d1e1ab613f892f" => :sierra
    sha256 "aa4b7f398b833663299922c8a3ee15bfd36058c75c8555f6054d7c0a84ce4e70" => :high_sierra
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
      --with-affine
      --interval-lib=filib
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
