Summary: The XAR project aims to provide an easily extensible archive format.
Name: xar
Version: 1.5.2
Release: 0
License: BSD
Group: Applications/Archiving
URL: http://code.google.com/p/%{name}/
Source: http://%{name}.googlecode.com/files/%{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%ifos linux
BuildRequires: libxml2-devel >= 2.6.11
BuildRequires: openssl-devel
BuildRequires: bzip2-devel
BuildRequires: zlib-devel
BuildRequires: /usr/bin/awk
%endif

%description
The XAR project aims to provide an easily extensible archive format. Important
design decisions include an easily extensible XML table of contents for random
access to archived files, storing the toc at the beginning of the archive to
allow for efficient handling of streamed archives, the ability to handle files
of arbitrarily large sizes, the ability to choose independent encodings for
individual files in the archive, the ability to store checksums for individual
files in both compressed and uncompressed form, and the ability to query the
table of content's rich meta-data.

%package devel
Summary: Libraries and header files required for xar.
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
Libraries and header files required for xar.

%prep
%setup -q -n %{name}-%{version}

%build
%configure --disable-static
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} install DESTDIR=%{buildroot}

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%ifos linux
%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig
%endif

%files
%defattr(-,root,root,-)
%doc LICENSE TODO
%{_bindir}/%{name}
%ifnos darwin
%{_libdir}/lib%{name}.so.*
%else
%{_libdir}/lib%{name}.*.dylib
%endif
%{_mandir}/man1/xar.1*

%files devel
%defattr(-,root,root,-)
%{_includedir}/%{name}/%{name}.h
%ifnos darwin
%{_libdir}/lib%{name}.so
%else
%{_libdir}/lib%{name}.dylib
%endif
%exclude %{_libdir}/lib%{name}.la

%changelog
* Wed Sep 12 2007 Anders F Bjorklund <afb@rpm5.org> 1.5.1-0
- fixed spec, made darwin compatible
- moved non-versioned lib from devel

* Mon May 07 2007 Rob Braun <bbraun@synack.net> 0:1.5-1
- 1.5
* Thu Feb 23 2006 Rob Braun <bbraun@opendarwin.org> - 0:1.2-1
- 1.4
* Mon Oct 24 2005 Rob Braun <bbraun@opendarwin.org> - 0:1.2-1
- 1.3
* Wed Sep 21 2005 Jason Corley <jason.corley@gmail.com> - 0:1.1-1
- 1.1
- correct library version
- add specific version to libxml requirements

* Fri Sep 09 2005 Jason Corley <jason.corley@gmail.com> - 0:1.0-1
- 1.0

* Sat Apr 23 2005 Jason Corley <jason.corley@gmail.com> - 0:0.0.0-0.20050423.0
- Initial RPM release.

