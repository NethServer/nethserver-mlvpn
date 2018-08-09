Summary: NethServer mlvpn configuration
Name: nethserver-mlvpn
Version: 0.0.1
Release: 1%{?dist}
License: GPL
URL: %{url_prefix}/%{name} 
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch

Requires: mlvpn
Requires: nethserver-base

BuildRequires: nethserver-devtools 

%description
NethServer mlvpn configuration

%prep
%setup

%build
perl createlinks
mkdir -p root%{perl_vendorlib}
mv -v lib/perl/NethServer root%{perl_vendorlib}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/var/log/mlvpn
(cd root; find . -depth -print | cpio -dump %{buildroot})
%{genfilelist} %{buildroot} \
  --dir /var/log/mlvpn 'attr(0700,root,root)' \
  --file /etc/mlvpn/mlvpn_updown_shorewall.sh 'attr(0700,root,root)' \
  > %{name}-%{version}-filelist

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
%doc COPYING
%dir %{_nseventsdir}/%{name}-update
%config(noreplace) /etc/httpd/conf.d/mlvpn.conf

%changelog
