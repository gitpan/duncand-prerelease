=head1 NAME

CGI::WPM::SimpleUserIO - Abstracted user input/output in CGI, mod_perl, cmd line.

=cut

######################################################################

package CGI::WPM::SimpleUserIO;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.4';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Apache (when running under mod_perl only)
	HTTP::Headers 1.36 (earlier versions may work, but not tested)

=head2 Nonstandard Modules

	I<none>

=head1 SYNOPSIS

=head2 Example simplified from HTML::Application and modified to use this class.

	#!/usr/bin/perl
	use strict;
	use lib '/home/johndoe/myperl5/lib';

	# make new framework; set where our files are today

	require HTML::Application;
	my $globals = HTML::Application->new( "/home/johndoe/projects/aardvark" );

	# fetch the web user's input from environment or command line

	require CGI::WPM::SimpleUserIO;
	my $io = CGI::WPM::SimpleUserIO->new( 1 );
	
	# store user input in HTML::Application, remem script url in call-back urls
	
	$globals->url_base( $io->url_base() );
 	$globals->user_query( $io->user_query_str() );
 	$globals->user_post( $io->user_post_str() );
 	if( $globals->url_path_is_in_path_info() ) {
	 	$globals->user_path( $io->user_path_info_str() );
 	} else {
 		my $pname = $globals->url_path_query_param_name();
	 	$globals->user_path( lc( $globals->user_query_param( $pname ) ) );
		$globals->get_user_query_ref()->delete( $pname );
 	}

	# set up component context including file prefs and user path level
	
	$globals->set_prefs( "config.pl" );
	$globals->inc_user_path_level();
	
	# run our main program to do all the real work, now that its sandbox is ready
	
	$globals->call_component( 'Aardvark', 1 );
	
	# make an error message if the main program failed for some reason
	
	if( $globals->get_error() ) {
		$globals->page_title( 'Fatal Program Error' );
		$globals->set_page_body( <<__endquote );
	<H1>@{[$globals->page_title()]}</H1>
	<P>I'm sorry, but an error has occurred while trying to run Aardvark.  
	The problem could be temporary.  Click @{[$globals->recall_html('here')]} 
	to automatically try again, or come back later.
	<P>Details: @{[$globals->get_error()]}</P>
	__endquote
	}

	# send the user output

	my $http = $io->make_http_headers( $globals->http_status_code(), 
		$globals->http_content_type(), $globals->http_redirect_url() );
	$io->send_user_output( $http, $globals->http_body() || 
		$globals->page_as_string(), $globals->http_body_is_binary() );

	1;

=head1 DESCRIPTION

This Perl 5 object class provides some convenience methods for getting user input 
and sending user output by abstracting away the exact method of these actions.  
This class is designed to get input from both web users through the environment 
and from users debugging their scripts on the command line; user input can be 
gotten from either shell arguments and through standard input.  This class is 
designed to sense when it is running under mod_perl and use the appropriate 
Apache methods to send output; otherwise it prints to standard output which is 
suitable for both CGI and the command line.  This class is intended to be used 
with HTML::Application, which doesn't do any user input or output by itself, but 
you can also use it independently.

=cut

######################################################################

# These properties are set only once because they correspond to user 
# input that can only be gathered prior to this program starting up.
my $KEY_USER_PATH_INFO_STR = 'user_path_info_str';
my $KEY_USER_QUERY_STR     = 'user_query_str';
my $KEY_USER_POST_STR      = 'user_post_str';
my $KEY_IS_OVERSIZE_POST   = 'is_oversize_post';
my $KEY_USER_COOKIES_STR   = 'user_cookies_str';

# Constant values used in this class go here:
my $MAX_CONTENT_LENGTH = 100_000;  # currently limited to 100 kbytes

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 FUNCTIONS AND METHODS

=head2 new([ GATHER_INPUT_NOW ])

This function creates a new CGI::WPM::SimpleUserIO object and returns it.  If 
the optional parameter GATHER_INPUT_NOW is true then this method also calls 
gather_user_input() for you.

=cut

######################################################################

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$_[0] and $self->gather_user_input( @_ );
	return( $self );
}

######################################################################

=head2 gather_user_input()

This method will gather several types of user input from %ENV, <STDIN>, and @ARGV
where appropriate.  If $ENV{REQUEST_METHOD} is one of [GET,HEAD,POST] then this
method assumes we are online and gathers the "path info", "query string", post
data, and "http cookie" from the environment and standard in.  Only
$ENV{CONTENT_LENGTH} of post data is read normally, and none is read if the
content length is over 100KB of data; in the latter case, this object's "is
oversize post" property is set to true.  This method should only be called once
when online or the method may hang when trying to read more post data.  If this
method assumes we are not online then it will assume it is being debugged on the
command line.  This method will then first check $ARGV[1] for content, and if
present it will take @ARGV elements 1 thru 4 and assign them to the first 4
properties above.  ($ARGV[0] is reserved for the caller's use, such as to hold an
http host name.)  If we are offline and $ARGV[1] is empty then we will attempt to
read the 4 properties from standard in; one line is read for each and each is
preceeded with a user prompt on STDERR.  None of the gathered user input is 
parsed; you can retrieve the raw strings with the next 5 methods.

=cut

######################################################################

sub gather_user_input {
	my $self = shift( @_ );
	my ($path_info, $query, $post, $oversize, $cookies);

	if( $ENV{'REQUEST_METHOD'} =~ /^(GET|HEAD|POST)$/ ) {
		$path_info = $ENV{'PATH_INFO'};

		$query = $ENV{'QUERY_STRING'};
		$query ||= $ENV{'REDIRECT_QUERY_STRING'};
		
		if( $ENV{'CONTENT_LENGTH'} <= $MAX_CONTENT_LENGTH ) {
			read( STDIN, $post, $ENV{'CONTENT_LENGTH'} );
			chomp( $post );
		} else {  # post too large, error condition, post not taken
			$oversize = $MAX_CONTENT_LENGTH;
		}

		$cookies = $ENV{'HTTP_COOKIE'} || $ENV{'COOKIE'};

	} elsif( $ARGV[1] ) {  # allow caller to save $ARGV[0] for the http_host
		$path_info = $ARGV[1];
		$query = $ARGV[2];
		$post = $ARGV[3];
		$cookies = $ARGV[4];

	} else {
		print STDERR "offline mode: enter user path info on standard input\n";
		print STDERR "it must be all on one line\n";
		$path_info = <STDIN>;
		chomp( $path_info );

		print STDERR "offline mode: enter user query on standard input\n";
		print STDERR "it must be query-escaped and all on one line\n";
		$query = <STDIN>;
		chomp( $query );

		print STDERR "offline mode: enter user post on standard input\n";
		print STDERR "it must be query-escaped and all on one line\n";
		$post = <STDIN>;
		chomp( $post );

		print STDERR "offline mode: enter user cookies on standard input\n";
		print STDERR "they must be cookie-escaped and all on one line\n";
		$cookies = <STDIN>;
		chomp( $cookies );
	}

	$self->{$KEY_USER_PATH_INFO_STR} = $path_info;
	$self->{$KEY_USER_QUERY_STR}     = $query;
	$self->{$KEY_USER_POST_STR}      = $post;
	$self->{$KEY_IS_OVERSIZE_POST}   = $oversize;
	$self->{$KEY_USER_COOKIES_STR}   = $cookies;
}

######################################################################

=head2 user_path_info_str()

This method returns the raw "path_info" string.

=head2 user_query_str()

This method returns the raw "query_string".

=head2 user_post_str()

This method returns the raw "post" data as a string.

=head2 is_oversize_post()

This method returns true if $ENV{CONTENT_LENGTH} was over 100,000KB.

=head2 user_cookies_str()

This method returns the raw "http_cookie" string.

=cut

######################################################################

sub user_path_info_str { $_[0]->{$KEY_USER_PATH_INFO_STR} }
sub user_query_str     { $_[0]->{$KEY_USER_QUERY_STR}     }
sub user_post_str      { $_[0]->{$KEY_USER_POST_STR}      }
sub is_oversize_post   { $_[0]->{$KEY_IS_OVERSIZE_POST}   }
sub user_cookies_str   { $_[0]->{$KEY_USER_COOKIES_STR}   }

######################################################################

=head2 url_base()

This method constructs a probable "base url" that the current script was called 
as on the web.  It is approximately equal to "http://" + $ENV{HTTP_HOST} + ":"
$ENV{SERVER_PORT} + $ENV{SCRIPT_NAME}.  The port is omitted if it is 80 or 
undefined.  The http_host defaults to server_name and then "localhost" if it or 
server_name isn't defined.  The script_name is url-decoded.  This method's 
return value can be used in conjunction with appropriate path_info and 
query_string data to construct self-referencing urls that reinvoke this same 
script with or without persistant user input; post data can also be preserved 
with a form whose fields contain the post data and whose "action" url is this 
aforementioned self-referencing url.  Note that HTML::Application can do the 
self-referencing details for you if provided with a base_url() and other data.

=cut

######################################################################

sub url_base {
	my $host = $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || 'localhost';
	my $port = $ENV{'SERVER_PORT'} || 80;
	my $script = $ENV{'SCRIPT_NAME'};
	$script =~ tr/+/ /;
	$script =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return( 'http://'.$host.($port != 80 ? ":$port" : '').$script );
}

######################################################################

=head2 make_http_headers([ STATUS[, CONTENT_TYPE[, REDIRECT_URL]] ])

This method constructs a new HTTP::Headers object that is suitable for using in
the start of HTTP responses.  It uses all 3 arguments if they are provided in the
new headers object.  The first two result in "Status" and "Content-type" headers
respectively, and the third results in both "Uri" and "Location" headers. STATUS
defaults to "200 OK" if not defined, and likewise CONTENT_TYPE defaults to
"text/html"; these are suitable for a normal HTML page response.  If you want a
redirect response then you need to provide something like "301 Moved" as the
STATUS as this is not set automatically.

=cut

######################################################################

sub make_http_headers {
	my ($self, $status, $content_type, $redirect_url) = @_;
	$status ||= '200 OK';
	$content_type ||= 'text/html';

	require HTTP::Headers;
	my $http = HTTP::Headers->new();

	$http->header( 
		status => $status,
		content_type => $content_type,
	);

	if( $redirect_url ) {
		$http->header( 
			uri => $redirect_url,
			location => $redirect_url,
		);
	}

	return( $http );  # return HTTP headers object
}

######################################################################

=head2 send_user_output([ HTTP[, CONTENT[, IS_BINARY]] ])

This method will send several types of user output to the user as a complete HTTP
response. The argument HTTP is an HTTP::Headers object that is already
initialized with Status and anything else to be sent.  If this argument is not a
valid HTTP::Headers object then it defaults to being initialized by a call to
make_http_headers() with no arguments; suitable for an HTML page.  The argument
CONTENT is a scalar containing our HTTP body content; this is probably empty if
we are sending a redirect response.  This method checks if it is running under
mod_perl by seeing if $ENV{GATEWAY_INTERFACE} starts with "CGI-Perl" and if it
isn't then it assumes it is running as a CGI.  When running under mod_perl this
method will send HTTP headers using the cgi_header_out() method of a new
Apache->request() object; otherwise, the headers are printed to STDOUT.  The HTTP
body are then printed to STDOUT regardless of how we are running.  If the
argument IS_BINARY is true then we binmode() STDOUT before sending the HTTP body.

=cut

######################################################################

sub send_user_output {
	my ($self, $http, $content, $is_binary) = @_;

	ref( $http ) eq 'HTTP::Headers' or $http = $self->make_http_headers();

	if( $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl/ ) {
		require Apache;
		$| = 1;
		my $req = Apache->request();
		$http->scan( sub { $req->cgi_header_out( @_ ); } );

	} else {
		my $endl = "\015\012";  # cr + lf
		print STDOUT $http->as_string( $endl ).$endl;
	}
	
	$is_binary and binmode( STDOUT );
	print STDOUT $content;
}

######################################################################

1;
__END__

=head1 AUTHOR

Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.  However, I do request that this copyright information remain
attached to the file.  If you modify this module and redistribute a changed
version then please attach a note listing the modifications.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own code then please send me the URL.  Also, if you
make modifications to the module because it doesn't work the way you need, please
send me a copy so that I can roll desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 SEE ALSO

perl(1), HTML::Application, HTTP::Headers, Apache.

=cut
