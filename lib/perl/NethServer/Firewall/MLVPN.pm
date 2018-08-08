#
# Copyright (C) 2018 Nethesis S.r.l.
# http://www.nethesis.it - nethserver@nethesis.it
#
# This script is part of NethServer.
#
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
#
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see COPYING.
#

use strict;

package NethServer::Firewall::MLVPN;
use NethServer::Firewall qw(register_callback);
use esmith::DB::db;
use esmith::util;

register_callback(\&mlvpn_networks);

#
# Search inside virtual IPs and remote networks
#
sub mlvpn_networks
{
    my $value = shift;

    my $db = esmith::DB::db->open_ro('mlvpn');
    foreach ($db->get_all()) {
        my $type = $_->prop('type') || 'client';
        next if ($type ne 'server');
        my $nat = $_->prop('Nat') || 'disabled';
        my $nets = $_->prop('RemoteNetworks') || '';
        my $zone = 'mlvpn';
        if ($nat eq 'enabled') {
            $zone = 'loc';
        }

        # Search for tunnel IP
        my $local = $_->prop('LocalPeer') || next;
        # mask is hard-coded
        if (Net::IPv4Addr::ipv4_in_network("$local/24", $value)) {
            return $zone;
        }

        # Search inside remote networks
        foreach my $net (split(',',$nets)) {
            if (Net::IPv4Addr::ipv4_in_network($net, $value)) {
                return $zone;
            }
        }
    }
}
