package Baidu::BCS;
use strict;
use warnings;
use Carp;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use URI::Escape;
use JSON;
use Data::Dumper;
use Moo;

use Baidu::Bucket;

has host => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        ( $self->ssl ? "https://" : "http" ) . "bcs.duapp.com";
    }
);
has ak  => ( is => 'ro', required => 1 );
has sk  => ( is => 'ro', required => 1 );
has ssl => ( is => 'ro', default => sub { 0 } );
has ua => (
    is      => 'rw',
    default => sub {
        require LWP::UserAgent;
        LWP::UserAgent->new;
    }
);

sub sign {
    my $self = shift;
    my %opt = ref $_[0] ? %{ $_[0] } : @_;
    my ( $flags, $content );
    $opt{M} and do { $flags .= "M"; $content .= "Method=$opt{M}\n" };
    $opt{B} and do { $flags .= "B"; $content .= "Bucket=$opt{B}\n" };
    $opt{O} and do { $flags .= "O"; $content .= "Object=$opt{O}\n" };
    $opt{T} and do { $flags .= "T"; $content .= "Time=$opt{T}\n" };
    $opt{I} and do { $flags .= "I"; $content .= "Ip=$opt{I}\n" };
    $opt{S} and do { $flags .= "S"; $content .= "Size=$opt{S}\n" };
    $content = join "\n", $flags, $content;
    my $sign =
      uri_escape( encode_base64( hmac_sha1( $content, $self->sk ), '' ) );
    return sprintf( "%s/%s%s?sign=%s:%s:%s",
        $self->host, $opt{B}, $opt{O}, $flags, $self->ak, $sign );
}

sub list_buckets {
    my $self = shift;
    my $res = $self->ua->get( $self->sign( M => 'GET', B => '', O => '/' ) );
    [  map {$_->{bucket_name}} @{ decode_json $res->content} ];
}

sub bucket {
    my $self = shift;
    my $b = Baidu::Bucket->new( bcs => $self, bucket_name => shift );
    return $b;
}

1;

my $bcs = Baidu::BCS->new(
    host => 'http://bcs.duapp.com',
    ak => "xxxx",
    sk => "xxxx"
);
print Dumper $bcs->list_buckets();
my $b = $bcs->bucket('book-skyer');
print Dumper $b->get_acl;
my $o = $b->object('/readme');
$o->post_file('README.md');
$o->get_file("README.txt");
