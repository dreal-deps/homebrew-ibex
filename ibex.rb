class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/ibex-team/ibex-lib/archive/ibex-2.5.1.tar.gz"
  sha256 "6befc72b4c8170c0afede8a45446f6b06b5c93dc00507e50dd3af86bb78d5d9b"
  head "https://github.com/ibex-team/ibex-lib.git"

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkg-config" => :build
  depends_on "dreal-deps/coinor/clp"

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/clp_path.patch"
    sha256 "fb38af465951405f84c78fa9e3542330fc2725d38a2682f74040cf896e01c59c"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/use_std_min.patch"
    sha256 "828c0f35d02a705c360a92a9bba84a9a7e9e060a9f8c623b2b5e9c983fc09454"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --with-optim
      --with-affine
      --interval-lib=filib
      --clp-dir=/usr/local
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
