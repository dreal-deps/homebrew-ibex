class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.5.tar.gz"
  sha256 "3ea46e7a5b3ba6cdac59004949e5cdf26a5c7cf054f7968428f118dd86fb0597"
  head "https://github.com/ibex-team/ibex-lib.git"

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    cellar :any
     sha256 "e3d6b326a4e833f952325236f433b963836b31664679da0950804b0feb66a5bb" => :el_capitan
     sha256 "7d298038eef66c022f4cd1ea3abfce2f4935f60b26d4e574db81b65731be4d26" => :sierra
     sha256 "478cb870ccd6a488986d3261dff06fb82a05f859cead764e556a7d3e64b1ea69" => :high_sierra
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
