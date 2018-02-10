class IbexAT265 < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  head "https://github.com/dreal-deps/ibex-lib.git", :branch => "ibex-2.6.5"
  url "https://github.com/dreal-deps/ibex-lib/archive/ibex-2.6.5.tar.gz"
  sha256 "c54072c16871b805b9715b93238545489d8a9a88e731c956f174d807e598209b"
  revision 2

  bottle do
    root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
    cellar :any
     # sha256 "3f587499e869f2687d3f4f8e2f7dcf20b3d634649cb182f5bce59549caf1fd3e" => :el_capitan
     # sha256 "b9e2dc71bbfb71d58eb39ac2f47b0a0929ac97595bb74714b50c881359e3e8a4" => :sierra
       sha256 "f0a7035cbee2de6b7e7d989f678607815facddcfe2d12f1ea38fc5f83e36093f" => :high_sierra
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
