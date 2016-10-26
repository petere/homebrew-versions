class Rpm4 < Formula
  desc "RPM package manager"
  homepage "http://rpm.org/"
  #url "http://rpm.org/releases/testing/rpm-4.13.0-rc2.tar.bz2"
  #sha256 "4d31b39a79466973d8f1ae9894c286479d9c53442321ad5d6df0e7efe94cd20c"

  head do
    url "https://github.com/rpm-software-management/rpm.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "gettext"
  depends_on "libarchive"
  depends_on "nspr"
  depends_on "nss"

  def install
    # fixes audit warning "python modules have explicit framework
    # links"
    inreplace %w[
      python/Makefile.am
    ] do |s|
      s.gsub! "@WITH_PYTHON_LIB@", "$(WITH_PYTHON_LIB)"
    end

    system "autoreconf", "-f", "-i" if build.head?

    ENV.append "CPPFLAGS", "-I#{Formula["nspr"].opt_include}/nspr"
    ENV.append "CPPFLAGS", "-I#{Formula["nss"].opt_include}/nss"

    args = %W[
      --prefix=#{prefix}
      --localstatedir=#{var}
      --sysconfdir=#{etc}
      --disable-dependency-tracking
      --with-external-db
      --without-lua
      --enable-python
    ]

    inreplace %w[
      doc/fr/rpm.8
      doc/ja/rpm.8
      doc/ja/rpmbuild.8
      doc/ko/rpm.8
      doc/pl/rpm.8
      doc/pl/rpmbuild.8
      doc/rpm.8
      doc/rpmbuild.8
      doc/ru/rpm.8
      doc/sk/rpm.8
    ] do |s|
      s.gsub! "/usr/lib/rpm", HOMEBREW_PREFIX/"lib/rpm"
      s.gsub! "/etc/rpm", etc/"rpm"
      s.gsub! "/var/lib/rpm", var/"rpm"
    end

    inreplace %w[
      scripts/check-rpaths
      scripts/check-rpaths-worker
      scripts/find-provides
      scripts/find-requires
      scripts/rpmdb_loadcvt
      scripts/vpkg-provides.sh
    ] do |s|
      s.gsub! "/usr/lib/rpm", lib/"rpm"
    end

    system "./configure", *args
    system "make", "install", "WITH_PYTHON_LIB=-undefined dynamic_lookup"
  end

  def test_spec
    <<-EOS.undent
      Summary:   Test package
      Name:      test
      Version:   1.0
      Release:   1
      License:   Public Domain
      Group:     Development/Tools
      BuildArch: noarch

      %description
      Trivial test package

      %prep
      %build
      %install
      mkdir -p $RPM_BUILD_ROOT/tmp
      touch $RPM_BUILD_ROOT/tmp/test

      %files
      /tmp/test

      %changelog

    EOS
  end

  def rpmdir(macro)
    Pathname.new(`#{bin}/rpm --eval #{macro}`.chomp)
  end

  test do
    (testpath/"var/lib/rpm").mkpath
    (testpath/".rpmmacros").write <<-EOS.undent
      %_topdir		#{testpath}/var/lib/rpm
      %_specdir		%{_topdir}/SPECS
      %_tmppath		%{_topdir}/tmp
    EOS

    system "#{bin}/rpm", "-vv", "-qa", "--dbpath=#{testpath}"
    rpmdir("%_builddir").mkpath
    specfile = rpmdir("%_specdir")+"test.spec"
    specfile.write(test_spec)
    system "#{bin}/rpmbuild", "-ba", specfile
    assert File.exist?(testpath/"var/lib/rpm/SRPMS/test-1.0-1.src.rpm")
  end
end
