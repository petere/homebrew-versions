class Llvm36 < Formula
  homepage "http://llvm.org/"

  stable do
    url "http://llvm.org/releases/3.6.0/llvm-3.6.0.src.tar.xz"
    sha1 "6eb2b7381d924bb3f267281c9058c817d825d824"

    resource "clang" do
      url "http://llvm.org/releases/3.6.0/cfe-3.6.0.src.tar.xz"
      sha1 "06b252867a3d118c95ca279fd3c4ac05f6730551"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/releases/3.6.0/clang-tools-extra-3.6.0.src.tar.xz"
      sha1 "30c6acd7404b9abf0338110818fba255d5744978"
    end

    resource "compiler-rt" do
      url "http://llvm.org/releases/3.6.0/compiler-rt-3.6.0.src.tar.xz"
      sha1 "771cbf0535dce1ca3a3be022377781e32fdea70e"
    end

    resource "polly" do
      url "http://llvm.org/releases/3.6.0/polly-3.6.0.src.tar.xz"
      sha1 "f87ce93a2d71b72412c6424f07afb3b4df42aad9"
    end

    resource "lld" do
      url "http://llvm.org/releases/3.6.0/lld-3.6.0.src.tar.xz"
      sha1 "3d6e47c13e93530126eebc45f008d3dcaa6dd7d2"
    end

    resource "lldb" do
      url "http://llvm.org/releases/3.6.0/lldb-3.6.0.src.tar.xz"
      sha1 "f92c4bb7d9f0431285d068668b10d62512f36f03"
    end

    resource "libcxx" do
      url "http://llvm.org/releases/3.6.0/libcxx-3.6.0.src.tar.xz"
      sha1 "5445194366ae2291092fd2204030cb3d01ad6272"
    end

    resource "libcxxabi" do
      url "http://llvm.org/releases/3.6.0/libcxxabi-3.6.0.src.tar.xz"
      sha1 "b4bee624f82da67281f96596bc8523a8592ad1f0"
    end if MacOS.version <= :snow_leopard
  end

  bottle do
    root_url "https://homebrew.bintray.com/bottles-versions"
    sha1 "7e767063a60caaa665aafda0f68e9f21d948ce1b" => :yosemite
    sha1 "81dc1ed654d01110988be1d38d0c8b4056cbd557" => :mavericks
    sha1 "71c7d6eb4428c81ea800336b7c022df72f7dd02f" => :mountain_lion
  end


  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_36"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_36"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_36"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_36"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_36"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git"
    end

    resource "lldb" do
      url "http://llvm.org/git/lldb.git", :branch => "release_36"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_36"
    end

    resource "libcxxabi" do
      url "http://llvm.org/git/libcxxabi.git", :branch => "release_36"
    end if MacOS.version <= :snow_leopard
  end

  resource "isl" do
    url "http://repo.or.cz/w/isl.git/snapshot/0698f8436c523ecc742b13a9b3aa337cc2421fa2.tar.gz"
    sha1 "be4bfff65b9ab29785c4de414ca59c1abf70c626"
  end

  patch :DATA

  option :universal
  option "with-lld", "Build LLD linker"
  option "with-lldb", "Build LLDB debugger"
  option "with-asan", "Include support for -faddress-sanitizer (from compiler-rt)"
  option "with-all-targets", "Build all target backends"
  option "with-python", "Build lldb bindings against the python in PATH instead of system Python"
  option "without-shared", "Don't build LLVM as a shared library"
  option "without-assertions", "Speeds up LLVM, but provides less debug information"

  # required to build isl
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool"  => :build
  depends_on "pkg-config" => :build

  depends_on "gmp"
  depends_on "libffi" => :recommended

  depends_on "swig" if build.with? "lldb"
  depends_on :python => :optional

  # version suffix
  def ver
    "3.6"
  end

  # LLVM installs its own standard library which confuses stdlib checking.
  cxxstdlib_check :skip

  # Apple's libstdc++ is too old to build LLVM
  fails_with :gcc
  fails_with :llvm

  def install
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    clang_buildpath = buildpath/"tools/clang"
    libcxx_buildpath = buildpath/"projects/libcxx"
    libcxxabi_buildpath = buildpath/"libcxxabi" # build failure if put in projects due to no Makefile

    clang_buildpath.install resource("clang")
    libcxx_buildpath.install resource("libcxx")
    (buildpath/"tools/polly").install resource("polly")
    (buildpath/"tools/clang/tools/extra").install resource("clang-tools-extra")
    (buildpath/"tools/lld").install resource("lld") if build.with? "lld"
    (buildpath/"tools/lldb").install resource("lldb") if build.with? "lldb"
    (buildpath/"projects/compiler-rt").install resource("compiler-rt") if build.with? "asan"

    if build.universal?
      ENV.permit_arch_flags
      ENV["UNIVERSAL"] = "1"
      ENV["UNIVERSAL_ARCH"] = Hardware::CPU.universal_archs.join(" ")
    end

    ENV["REQUIRES_RTTI"] = "1"

    install_prefix = lib/"llvm-#{ver}"

    gmp_prefix = Formula["gmp"].opt_prefix
    isl_prefix = install_prefix/"libexec/isl"

    resource("isl").stage do
      system "./autogen.sh"
      system "./configure", "--disable-dependency-tracking",
                            "--disable-silent-rules",
                            "--prefix=#{isl_prefix}",
                            "--with-gmp=system",
                            "--with-gmp-prefix=#{gmp_prefix}"
      system "make"
      system "make", "install"
    end

    args = [
      "--prefix=#{install_prefix}",
      "--enable-optimized",
      "--disable-bindings",
      "--with-gmp=#{gmp_prefix}",
      "--with-isl=#{isl_prefix}",
    ]

    if build.with? "all-targets"
      args << "--enable-targets=all"
    else
      args << "--enable-targets=host"
    end

    args << "--enable-shared" if build.with? "shared"

    args << "--disable-assertions" if build.without? "assertions"

    args << "--enable-libffi" if build.with? "libffi"

    system "./configure", *args
    system "make", "VERBOSE=1"
    system "make", "VERBOSE=1", "install"

    if MacOS.version <= :snow_leopard
      libcxxabi_buildpath.install resource("libcxxabi")

      cd libcxxabi_buildpath/"lib" do
        # Set rpath to save user from setting DYLD_LIBRARY_PATH
        inreplace "buildit", "-install_name /usr/lib/libc++abi.dylib", "-install_name #{install_prefix}/usr/lib/libc++abi.dylib"

        ENV["CC"] = "#{install_prefix}/bin/clang"
        ENV["CXX"] = "#{install_prefix}/bin/clang++"
        ENV["TRIPLE"] = "*-apple-*"
        system "./buildit"
        (install_prefix/"usr/lib").install "libc++abi.dylib"
        cp libcxxabi_buildpath/"include/cxxabi.h", install_prefix/"lib/c++/v1"
      end

      # Snow Leopard make rules hardcode libc++ and libc++abi path.
      # Change to Cellar path here.
      inreplace "#{libcxx_buildpath}/lib/buildit" do |s|
        s.gsub! "-install_name /usr/lib/libc++.1.dylib", "-install_name #{install_prefix}/usr/lib/libc++.1.dylib"
        s.gsub! "-Wl,-reexport_library,/usr/lib/libc++abi.dylib", "-Wl,-reexport_library,#{install_prefix}/usr/lib/libc++abi.dylib"
      end

      # On Snow Leopard and older system libc++abi is not shipped but
      # needed here. It is hard to tweak environment settings to change
      # include path as libc++ uses a custom build script, so just
      # symlink the needed header here.
      ln_s libcxxabi_buildpath/"include/cxxabi.h", libcxx_buildpath/"include"
    end

    # Putting libcxx in projects only ensures that headers are installed.
    # Manually "make install" to actually install the shared libs.
    libcxx_make_args = [
      # Use the built clang for building
      "CC=#{install_prefix}/bin/clang",
      "CXX=#{install_prefix}/bin/clang++",
      # Properly set deployment target, which is needed for Snow Leopard
      "MACOSX_DEPLOYMENT_TARGET=#{MacOS.version}",
      # The following flags are needed so it can be installed correctly.
      "DSTROOT=#{install_prefix}",
      "SYMROOT=#{libcxx_buildpath}",
    ]

    system "make", "-C", libcxx_buildpath, "install", *libcxx_make_args

    (share/"clang-#{ver}/tools").install Dir["tools/clang/tools/scan-{build,view}"]
    inreplace share/"clang-#{ver}/tools/scan-build/scan-build", "$RealBin/bin/clang", install_prefix/"bin/clang"
    ln_s share/"clang-#{ver}/tools/scan-build/scan-build", install_prefix/"bin"
    ln_s share/"clang-#{ver}/tools/scan-view/scan-view", install_prefix/"bin"
    (install_prefix/"share/man/man1").install share/"clang-#{ver}/tools/scan-build/scan-build.1"

    (lib/"python2.7/site-packages").install "bindings/python/llvm" => "llvm-#{ver}",
                                            clang_buildpath/"bindings/python/clang" => "clang-#{ver}"
    (lib/"python2.7/site-packages").install_symlink install_prefix/"lib/python2.7/site-packages/lldb" => "lldb-#{ver}" if build.with? "lldb"

    Dir.glob(install_prefix/"bin/*") do |exec_path|
      basename = File.basename(exec_path)
      bin.install_symlink exec_path => "#{basename}-#{ver}"
    end

    Dir.glob(install_prefix/"share/man/man1/*") do |manpage|
      basename = File.basename(manpage, ".1")
      man1.install_symlink manpage => "#{basename}-#{ver}.1"
    end
  end

  test do
    system "#{bin}/llvm-config-#{ver}", "--version"
  end

  def caveats; <<-EOS.undent
    Extra tools are installed in #{opt_share}/clang-#{ver}

    To link to libc++, something like the following is required:
      CXX="clang++-#{ver} -stdlib=libc++"
      CXXFLAGS="$CXXFLAGS -nostdinc++ -I#{opt_lib}/llvm-#{ver}/include/c++/v1"
      LDFLAGS="$LDFLAGS -L#{opt_lib}/llvm-#{ver}/lib"
    EOS
  end
end

__END__
diff --git a/Makefile.rules b/Makefile.rules
index ebebc0a..b0bb378 100644
--- a/Makefile.rules
+++ b/Makefile.rules
@@ -599,7 +599,12 @@ ifneq ($(HOST_OS), $(filter $(HOST_OS), Cygwin MingW))
 ifneq ($(HOST_OS),Darwin)
   LD.Flags += $(RPATH) -Wl,'$$ORIGIN'
 else
-  LD.Flags += -Wl,-install_name  -Wl,"@rpath/lib$(LIBRARYNAME)$(SHLIBEXT)"
+  LD.Flags += -Wl,-install_name
+  ifdef LOADABLE_MODULE
+    LD.Flags += -Wl,"$(PROJ_libdir)/$(LIBRARYNAME)$(SHLIBEXT)"
+  else
+    LD.Flags += -Wl,"$(PROJ_libdir)/$(SharedPrefix)$(LIBRARYNAME)$(SHLIBEXT)"
+  endif
 endif
 endif
 endif
