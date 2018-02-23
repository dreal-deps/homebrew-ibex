class IbexAT265 < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  head "https://github.com/dreal-deps/ibex-lib.git", :branch => "ibex-2.6.5"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.5.tar.gz"
  sha256 "d2c99bf812750116ff1211771f0962137dd03903f670a0ce67bff06e13c7be5e"
  revision 4

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    cellar :any
       # sha256 "ba03ae63c4257fa502623145ab3e488069ae3e83f933a00becbf53254dac0f48" => :el_capitan
       # sha256 "5a4feb24160b05fe05422864524d7d10e35187ab41d009bcddd8315716e672d6" => :sierra
       sha256 "b2f13961709592c613210a8606f5eba26295c1fedb6853df4d0037c6685f04a3" => :high_sierra
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "dreal-deps/coinor/clp"

  keg_only :versioned_formula
  option :cxx11
  
  def install
    ENV.cxx11
    ENV.append "CXXFLAGS", "-std=c++11"
    print "#{prefix}"
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
    (pkgshare/"examples/symb01.txt").write <<~EOS
      function f(x)
        return ((2*x,-x);(-x,3*x));
      end
    EOS

    inreplace "#{share}/pkgconfig/ibex.pc", prefix, opt_prefix
  end

  test do
    cp_r (pkgshare/"examples").children, testpath
    cp pkgshare/"benchs/cyclohexan3D.bch", testpath/"c3D.bch"

    # so that pkg-config can remain a build-time only dependency
    inreplace %w[makefile slam/makefile] do |s|
      s.gsub! /CXXFLAGS.*pkg-config --cflags ibex./,
              "CXXFLAGS := -I#{opt_include} -I#{opt_include}/ibex "\
                          "-I#{opt_include}/ibex/3rd/coin -I#{opt_include}/ibex/3rd"
      s.gsub! /LIBS.*pkg-config --libs  ibex./, "LIBS := -L#{opt_lib} -libex"
    end

    system "make", "ctc01", "ctc02", "symb01", "solver01", "solver02"
    system "make", "-C", "slam", "slam1", "slam2", "slam3"
    %w[ctc01 ctc02 symb01].each { |a| system "./#{a}" }
    %w[solver01 solver02].each { |a| system "./#{a}", "c3D.bch", "1e-05", "10" }
    %w[slam1 slam2 slam3].each { |a| system "./slam/#{a}" }
  end
end
