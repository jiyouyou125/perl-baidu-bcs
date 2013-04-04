package Baidu::Object;
use strict;
use warnings;
use Moo;
use Data::Dumper;

has bucket =>
  ( is => 'ro', required => 1, handles => [qw/sign bucket_name ua/] );
has name => ( is => 'ro', required => 1 );
has etag => ( is => 'rw' );
has version => ( is => 'rw' );

foreach my $method (qw/put post get head delete/) {
    has $method . "_url" => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->sign(
                M => uc $method,
                B => $self->bucket_name,
                O => $self->name
            );
        }
    );
}

sub put {
    my $self    = shift;
    my $content = shift;
    my $headers = shift;
    $self->ua->put( $self->put_url, );
}

sub post_file {
    my $self = shift;
    my $file = shift;
    my $res = $self->ua->post(
        $self->post_url,
        [ filename => [$file] ],
        'Content-Type' => 'form-data'
    );
   $self->handle_response($res);
}

sub get_file {
    my $self = shift;
    my $file = shift;
    my $res  = $self->ua->get( $self->get_url, ':content_file' => $file );
    $self->handle_response($res);
}

sub handle_response {
    my $self = shift;
    my $res  = shift;
    $self->etag( $res->header("etag") );
    $self->version( $res->header('x-bs-version') );
}

1;
