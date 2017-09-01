class Ibex < Formula
  desc "C++ library for constraint processing over real numbers."
  homepage "http://www.ibex-lib.org/"
  url "https://github.com/ibex-team/ibex-lib/archive/ibex-2.5.1.tar.gz"
  sha256 "6befc72b4c8170c0afede8a45446f6b06b5c93dc00507e50dd3af86bb78d5d9b"
  head "https://github.com/ibex-team/ibex-lib.git"
  revision 2

# bottle do
#   root_url 'https://dl.bintray.com/dreal/homebrew-ibex'
#   sha256 "f20b38a008491bb844011546dd6dca6751ce1606de299a55c8264328c392ec67" => :sierra
# end

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
    sha256 "d04aab6a6452ab93c3d3341e62df52950f0927715c1cc5e2db2914cc6901e891"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/include_what_you_use.patch"
    sha256 "98b4954abe86e9db9aa25b436458d7ff219ff9323f609968dc035a111011b7c6"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/filib_log_interval.patch"
    sha256 "f86381845a4a6e44e9bfbe703ea3075c203ea8886eb7a7c1903badf63278865e"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/add_coin_clp_include.patch"
    sha256 "ed605060744bbe2adbedcf7e08b26be8918a81ae61d37c2de24dd65af483e2b8"
  end


  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/filibsrc-3.0.2.2.all.all.patch.patch"
    sha256 "688ed867b681900fb270dd6794874179913f5dd7cbb24f9faea680872164d32f"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/make_interval_vector_nothrow_move_constructible.patch"
    sha256 "3f5240b3847acaedf7e5d99542e39db12f41f1e422f7c7e691a204d982906794"
  end

  patch do
    url "https://raw.githubusercontent.com/dreal-deps/homebrew-ibex/master/use_construct_on_first_use_idiom.patch"
    sha256 "b7d8360dc12e9b8467ddb72ecdae9b768396ae8c7274c74320884a04e79827e5"
  end

  def install
    ENV.cxx11
    ENV.append "CXXFLAGS", "-std=c++11"
    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --with-optim
      --with-affine
      --interval-lib=filib
      --clp-path=/usr/local
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
