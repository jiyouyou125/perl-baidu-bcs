package Baidu::Bucket;
use strict;
use warnings;
use Moo;

use Baidu::Object;

has bcs => ( is => 'ro', required => 1, handles => [qw/sign ua/] );
has bucket_name => ( is => 'ro', required => 1 );

foreach my $method (qw/put get head delete/) {
    has $method . "_url" => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->sign( M => uc $method, B => $self->bucket_name, O => '/' );
        }
    );
}

sub object {
    my $self   = shift;
    my $object = shift;
    return Baidu::Object->new( bucket => $self, name => $object );
}

sub create {
    my $self = shift;
    return $self->ua->put( $self->put_url );
}

sub delete {
    my $self = shift;
    return $self->ua->delete( $self->delete_url );
}

sub set_acl {
    my $self = shift;
    my $acl  = shift;
    return $self->ua->put( $self->put_url . "&acl=1", $acl );
}

sub get_acl {
    my $self = shift;
    return $self->ua->get( $self->get_url . "&acl=1" )->content;
}

sub make_public {
    my $self = shift;
    my $acl =
qq!{"statements":[{"action":["*"],"effect":"allow","resource":["%s/"],"user":["*"]}]}!;
    $self->set_acl( sprintf $acl, $self->bucket_name );
}

1;
