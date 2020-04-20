package Zadm::Schema::KVM;
use Mojo::Base 'Zadm::Schema::base';

my $SCHEMA;
has schema => sub {
    my $self = shift;

    my $dp = Data::Processor->new($self->SUPER::schema);
    my $ec = $dp->merge_schema($self->$SCHEMA);

    $ec->count and Mojo::Exception->throw(join ("\n", map { $_->stringify } @{$ec->{errors}}));

    # KVM and derived zones do not have 'dns-domain' or 'resolvers' properties; drop them
    delete $dp->schema->{$_} for qw(dns-domain resolvers);

    return $dp->schema;
};

$SCHEMA = sub {
    my $self = shift;

    return {
    bootdisk    => {
        optional    => 1,
        description => 'boot disk',
        example     => '"bootdisk" : "rpool/hdd-bhyve0"',
        validator   => $self->sv->zvol,
        transformer => $self->sv->stripDev,
        'x-attr'    => 1,
    },
    bootorder   => {
        optional    => 1,
        default     => 'cd',
        description => 'boot order',
        example     => '"bootorder" : "cd"',
        validator   => $self->sv->regexp(qr/^[a-z]+$/),
        'x-attr'    => 1,
    },
    cdrom       => {
        optional    => 1,
        description => 'path to iso file',
        example     => '"cdrom" : "/tmp/omnios-bloody.iso"',
        validator   => $self->sv->file('<', 'cannot open cdrom path'),
        'x-attr'    => 1,
    },
    console     => {
        optional    => 1,
        description => 'console',
        example     => '"console" : "socket,/tmp/vm.com1,wait"',
        validator   => sub { return undef; },
        'x-attr'    => 1,
    },
    disk        => {
        optional    => 1,
        array       => 1,
        description => 'disks',
        example     => '"disk" : "rpool/hdd_bhyve0_data"',
        validator   => $self->sv->zvol,
        transformer => $self->sv->stripDev,
        'x-attr'    => 1,
    },
    diskif      => {
        optional    => 1,
        description => 'disk type',
        default     => 'virtio',
        example     => '"diskif" : "virtio"',
        validator   => $self->sv->elemOf(qw(virtio ahci)),
        'x-attr'    => 1,
    },
    netif       => {
        optional    => 1,
        description => 'network type',
        default     => 'virtio',
        example     => '"netif" : "virtio"',
        validator   => $self->sv->elemOf(qw(virtio e1000)),
        'x-attr'    => 1,
    },
    ram         => {
        description => 'RAM',
        example     => '"ram" : "1024"',
        validator   => $self->sv->regexp(qr/^\d+[kMGTPE]?$/),
        'x-attr'    => 1,
    },
    type        => {
        optional    => 1,
        description => 'machine type',
        default     => 'generic',
        example     => '"type" : "generic"',
        validator   => $self->sv->elemOf(qw(generic windows openbsd)),
        'x-attr'    => 1,
    },
    vcpus       => {
        description => 'CPU',
        default     => 1,
        example     => '"vcpus" : "1"',
        validator   => $self->sv->vcpus,
        'x-attr'    => 1,
    },
    vnc         => {
        description => 'VNC',
        default     => 'off',
        example     => '"vnc" : "on"',
        validator   => sub { return undef; },
        'x-attr'    => 1,
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