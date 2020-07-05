package Zadm::Schema::base;
use Mojo::Base -base;

use Zadm::Validator;
use Data::Processor;

has log   => sub { Mojo::Log->new(level => 'debug') };
has sv    => sub { Zadm::Validator->new(log => shift->log) };
has brand => sub { lc ((split /::/, ref shift)[-1]) };

has schema => sub {
    my $self = shift;

    return {
    zonename    => {
        description => 'name of zone',
        validator   => $self->sv->regexp(qr/^[-\w]+$/, 'zonename not valid'),
    },
    zonepath    => {
        description => 'path to zone root',
        example     => '"zonepath" : "/zones/mykvm"',
        validator   => $self->sv->zonePath,
    },
    autoboot    => {
        optional    => 1,
        description => 'boot zone automatically',
        validator   => $self->sv->bool,
    },
    bootargs    => {
        optional    => 1,
        description => 'boot arguments for zone',
        validator   => sub { return undef },
    },
    pool        => {
        optional    => 1,
        description => 'name of the resource pool this zone must be bound to',
        validator   => sub { return undef },
    },
    limitpriv   => {
        description => 'the maximum set of privileges any process in this zone can obtain',
        default     => 'default',
        validator   => $self->sv->regexp(qr/^[-\w,]+$/, 'limitpriv not valid'),
    },
    brand       => {
        description => "the zone's brand type",
        default     => 'lipkg',
        validator   => sub { return undef },
    },
    'ip-type'   => {
        description => 'ip-type of zone. can either be "exclusive" or "shared"',
        default     => 'exclusive',
        validator   => $self->sv->elemOf(qw(exclusive shared)),
    },
    hostid      => {
        optional    => 1,
        description => 'emulated 32-bit host identifier',
        validator   => $self->sv->regexp(qr/^(?:[\da-f]{1,8}|)$/i, 'hostid not valid'),
    },
    'cpu-shares'    => {
        optional    => 1,
        description => 'the number of Fair Share Scheduler (FSS) shares',
        validator   => $self->sv->regexp(qr/^\d+$/, 'cpu-shares not valid'),
    },
    'max-lwps'    => {
        optional    => 1,
        description => 'the maximum number of LWPs simultaneously available',
        validator   => $self->sv->regexp(qr/^\d+$/, 'max-lwps not valid'),
    },
    'max-msg-ids'    => {
        optional    => 1,
        description => 'the maximum number of message queue IDs allowed',
        validator   => $self->sv->regexp(qr/^\d+$/, 'max-msg-ids not valid'),
    },
    'max-sem-ids'    => {
        optional    => 1,
        description => 'the maximum number of semaphore IDs allowed',
        validator   => $self->sv->regexp(qr/^\d+$/, 'max-sem-ids not valid'),
    },
    'max-shm-ids'    => {
        optional    => 1,
        description => 'the maximum number of shared memory IDs allowed',
        validator   => $self->sv->regexp(qr/^\d+$/, 'max-shm-ids not valid'),
    },
    'max-shm-memory'    => {
        optional    => 1,
        description => 'the maximum amount of shared memory allowed',
        validator   => $self->sv->regexp(qr/^\d+[KMGT]?$/i, 'max-shm-memory not valid'),
    },
    'scheduling-class'  => {
        optional    => 1,
        description => 'Specifies the scheduling class used for processes running',
        validator   => sub { return undef },
    },
    'fs-allowed'    => {
        optional    => 1,
        description => 'a comma-separated list of additional filesystems that may be mounted',
        validator   => $self->sv->regexp(qr/^(?:[-\w,]+|)$/, 'fs-allowed not valid'),
    },
    'dns-domain'    => {
        optional    => 1,
        description => 'DNS search domain',
        example     => '"dns-domain" : "example.com"',
        validator   => $self->sv->regexp(qr/^[-\w.]+$/, 'expected a valid domain name'),
        'x-attr'    => 1,
    },
    resolvers       => {
        optional    => 1,
        array       => 1,
        description => 'DNS resolvers',
        example     => '"resolvers" : [ "8.8.8.8", "8.8.4.4" ]',
        validator   => $self->sv->ip,
        'x-attr'    => 1,
    },
    attr    => {
        optional    => 1,
        array       => 1,
        description => 'generic attributes',
        members     => {
            name    => {
                description => 'attribute name',
                validator   => sub { return undef },
            },
            type    => {
                description => 'attribute type',
                validator   => sub { return undef },
            },
            value   => {
                description => 'attribute value',
                validator   => sub { return undef },
            },
        },
    },
    'capped-cpu'    => {
        optional    => 1,
        description => 'limits for CPU usage',
        members     => {
            ncpus       => {
                description => 'sets the limit on the amount of CPU time. value is the percentage of a single CPU',
                validator   => $self->sv->regexp(qr/^(?:\d*\.\d+|\d+\.\d*)$/, 'ncpus value not valid. check man zonecfg'),
            },
        },
    },
    'capped-memory' => {
        optional    => 1,
        description => 'limits for physical, swap, and locked memory',
        members     => {
            physical    => {
                optional    => 1,
                description => 'limits of physical memory. can be suffixed by (K, M, G, T)',
                validator   => $self->sv->regexp(qr/^\d+[KMGT]?$/i, 'physical capped-memory is not valid. check man zonecfg'),
            },
            swap    => {
                optional    => 1,
                description => 'limits of swap memory. can be suffixed by (K, M, G, T)',
                validator   => $self->sv->regexp(qr/^\d+[KMGT]?$/i, 'swap capped-memory is not valid. check man zonecfg'),
            },
            locked    => {
                optional    => 1,
                description => 'limits of locked memory. can be suffixed by (K, M, G, T)',
                validator   => $self->sv->regexp(qr/^\d+[KMGT]?$/i, 'locked capped-memory is not valid. check man zonecfg'),
            },
        },
    },
    dataset => {
        optional    => 1,
        array       => 1,
        description => 'ZFS dataset',
        members => {
            name    => {
                description => 'the name of a ZFS dataset to be accessed from within the zone',
                validator   => $self->sv->regexp(qr/^\w[-\w\/]+$/, 'dataset name not valid. check man zfs'),
            },
        },
    },
    'dedicated-cpu' => {
        optional    => 1,
        description => "subset of the system's processors dedicated to this zone while it is running",
        members     => {
            ncpus   => {
                description => "the number of cpus that should be assigned for this zone's exclusive use",
                validator   => $self->sv->regexp(qr/^\d+(?:-\d+)?$/, 'dedicated-cpu ncpus not valid. check man zonecfg'),
            },
            importance  => {
                optional    => 1,
                description => 'specifies the pset.importance value for use by poold',
                validator   => sub { return undef },
            },
        },
    },
    device  => {
        optional    => 1,
        array       => 1,
        description => 'device',
        members     => {
            match   => {
                description => 'device name to match',
                validator   => sub { return undef },
            },
        },
    },
    fs  => {
        optional    => 1,
        array       => 1,
        description => 'file-system',
        members     => {
            dir     => {
                description => 'directory of the mounted filesystem',
                validator   => $self->sv->regexp(qr/^\/[-\w\/\.]+$/, 'dir is not a valid directory'),
            },
            special => {
                description => 'path of fs to be mounted',
                validator   => $self->sv->regexp(qr/^[-\w\/\.]+$/, 'special is not valid'),
            },
            raw     => {
                optional    => 1,
                description => 'path of raw disk',
                validator   => $self->sv->regexp(qr/^\/[-\w\/]+$/, 'raw is not valid'),
            },
            type    => {
                description => 'type of fs',
                validator   => $self->sv->elemOf(qw(lofs zfs)),
            },
            options => {
                optional    => 1,
                array       => 1,
                description => 'mounting options',
                validator   => $self->sv->regexp(qr/^\w+$/, 'options not valid'),
            },
        },
    },
    net => {
        optional    => 1,
        array       => 1,
        description => 'network interface',
        members     => {
            address     => {
                optional    => 1,
                description => 'IP address of network interface',
                validator   => $self->sv->cidr,
            },
            physical    => {
                description => 'network interface',
                validator   => $self->sv->zoneNic,
            },
            defrouter   => {
                optional    => 1,
                description => 'IP address of default router',
                validator   => $self->sv->ip,
            },
            'allowed-address' => {
                optional    => 1,
                description => 'IP address of the zone',
                validator   => $self->sv->cidr,
            },
            'global-nic' => {
                optional    => 1,
                description => 'GZ network interface',
                validator   => $self->sv->globalNic,
            },
            'mac-addr'  => {
                optional    => 1,
                description => 'MAC address of the interface',
                validator   => $self->sv->macaddr,
            },
            over        => {
                optional    => 1,
                description => 'link where vnic traffic goes over',
                example     => '"over" : "igb0"',
                validator   => $self->sv->globalNic,
            },
        },
    },
    rctl    => {
        optional    => 1,
        array       => 1,
        description => 'resource control',
        members => {
            name    => {
                description => 'resource name',
                validator   => $self->sv->regexp(qr/^.+$/, 'Expected a string'),
            },
            value   => {
                description => 'resource value',
                members     => {
                    priv        => {
                        validator   => $self->sv->regexp(qr/^.+$/, 'Expected a string'),
                    },
                    limit       => {
                        validator   => $self->sv->regexp(qr/^.+$/, 'Expected a string'),
                    },
                    action      => {
                        validator   => $self->sv->regexp(qr/^.+$/, 'Expected a string'),
                    },
                },
            },
        },
    },
    admin   => {
        optional    => 1,
        description => 'delegate zone administration to named user',
        members => {
            user    => {
                description => 'username',
                validator   => $self->sv->regexp(qr/^\w+$/, 'Expected a valid username'),
            },
            auths   => {
                description => 'permissions set for user',
                # TODO: need to add a list of valid auths values
                validator   => $self->sv->regexp(qr/^\w+$/, 'Expexted valid auths'),
            },
        },
    },
}};

1;

__END__

=head1 COPYRIGHT

Copyright 2020 OmniOS Community Edition (OmniOSce) Association.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.
This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.
You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Dominik Hassler E<lt>hadfl@omniosce.orgE<gt>>

=head1 HISTORY

2020-04-12 had Initial Version

=cut
