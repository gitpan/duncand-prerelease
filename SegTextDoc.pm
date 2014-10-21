=head1 NAME

CGI::WPM::SegTextDoc - Perl module that is a subclass of CGI::WPM::Base and
displays a static text page, which can be in multiple segments.

=cut

######################################################################

package CGI::WPM::SegTextDoc;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.34';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	CGI::WPM::Base 0.34
	CGI::WPM::Globals 0.34
	CGI::WPM::Static 0.34

=cut

######################################################################

use CGI::WPM::Base 0.34;
@ISA = qw(CGI::WPM::Base);
use CGI::WPM::Static 0.34;

######################################################################

=head1 SYNOPSIS

=head2 Display A Text File In Multiple Segments

	require CGI::WPM::Globals;
	my $globals = CGI::WPM::Globals->new( "/path/to/site/files" );

	$globals->user_vrp( lc( $globals->user_input_param(  # fetch extra path info...
		$globals->vrp_param_name( 'path' ) ) ) );  # to know what page user wants
	$globals->current_user_vrp_level( 1 );  # get ready to examine start of vrp
	
	require CGI::WPM::Static;
	$globals->move_site_prefs( {
		title => 'Index of the World',
		author => 'Jules Verne',
		created => 'Version 1.0, first created 1993 June 24',
		updated => 'Version 3.1, last modified 2000 November 18',
		filename => 'jv_world.txt',
		segments => 24,
	} );
	CGI::WPM::Static->execute( $globals );  # content-type: text/html
	
	$globals->send_to_user();

I<You need to have a subdirectory named "jv_world" that contains the 24 files 
that correspond to the segments, named "jv_world_001.txt" through "...024.txt".>

=head2 Display A Text File All On One Page

	$globals->move_site_prefs( {
		title => 'Pizza Joints In New York',
		author => 'Oscar Wilder',
		created => 'Version 0.5, first created 1997 February 17',
		updated => 'Version 1.2, last modified 1998 March 8',
		filename => 'ow_pizza.txt',
		segments => 1,  # also the default
	} );

I<You need to have a single file named "ow_pizza.txt", not in a subdirectory.>

=head1 DESCRIPTION

I<This POD is coming when I get the time to write it.>

When the file is in multiple segments, a subdirectory is used to hold the pieces.  
When the file is in one part, there is no subdirectory.  Multipart documents have 
a navigation bar automatically generated to go between them.  Documents are 
assumed to be plain text, and are HTML escaped.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

This module inherits its entire public interface from CGI::WPM::Base.  Please see 
the POD for that module so you know how to call this one.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	title    # title of the document
	author   # who made the document
	created  # date and number of first version
	updated  # date and number of newest version
	filename # common part of filename for pieces
	segments # number of pieces doc is in

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site global preferences:

# Keys for items in site page preferences:
my $PKEY_TITLE = 'title';        # title of the document
my $PKEY_AUTHOR = 'author';      # who made the document
my $PKEY_CREATED = 'created';    # date and number of first version
my $PKEY_UPDATED = 'updated';    # date and number of newest version
my $PKEY_FILENAME = 'filename';  # common part of filename for pieces
my $PKEY_SEGMENTS = 'segments';  # number of pieces doc is in

# Constant values used in this class go here:

######################################################################
# This is provided so CGI::WPM::Base->dispatch_by_user() can call it.

sub _dispatch_by_user {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	
	my $segments = $rh_prefs->{$PKEY_SEGMENTS};
	$segments >= 1 or $rh_prefs->{$PKEY_SEGMENTS} = $segments = 1;

	my $curr_seg_num = $globals->current_user_vrp_element();
	$curr_seg_num >= 1 or $curr_seg_num = 1;
	$curr_seg_num <= $segments or $curr_seg_num = $segments;
	$globals->current_user_vrp_element( $curr_seg_num );
	
	$self->get_curr_seg_content();  # sets an error if it didn't work
	unless( $globals->get_error() ) {
		if( $segments > 1 ) {
			$self->attach_document_navbar();
		}
		$self->attach_document_header();
	}
	
	# This is provided just so usage listings sorted alphabetically 
	# will show all the parts in the correct order.
	$globals->current_user_vrp_element( sprintf( "%3.3d", $curr_seg_num ) );
}

######################################################################

sub get_curr_seg_content {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();
	my $is_multi_segmented = $rh_prefs->{$PKEY_SEGMENTS} > 1;

	my ($base, $ext) = ($rh_prefs->{$PKEY_FILENAME} =~ m/^([^\.]*)(.*)$/);
	my $seg_num_str = $is_multi_segmented ?
		'_'.sprintf( "%3.3d", $globals->current_user_vrp_element() ) : '';

	my $wpm_prefs = {
		filename => "$base$seg_num_str$ext",
		is_text => 1,
	};

	$is_multi_segmented and $globals->move_current_srp( $base );
	$globals->move_site_prefs( $wpm_prefs );

	my $wpm = CGI::WPM::Static->new( $globals );
	$wpm->dispatch_by_user();  # sets error if content couldn't be read

	$globals->restore_site_prefs();
	$is_multi_segmented and $globals->restore_last_srp();
}

######################################################################

sub attach_document_navbar {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	my $segments = $globals->site_prefs()->{$PKEY_SEGMENTS};
	my $curr_seg_num = $globals->current_user_vrp_element();
	my $common_url = $globals->persistant_vrp_url( '', 1 );

	my @seg_list_html = ();
	foreach my $seg_num (1..$segments) {
		if( $seg_num == $curr_seg_num ) {
			push( @seg_list_html, "$seg_num\n" );
		} else {
			push( @seg_list_html, 
				"<A HREF=\"$common_url$seg_num\">$seg_num</A>\n" );
		}
	}
	
	my $prev_seg_html = ($curr_seg_num == 1) ? "Previous\n" :
		"<A HREF=\"$common_url@{[$curr_seg_num-1]}\">Previous</A>\n";
	
	my $next_seg_html = ($curr_seg_num == $segments) ? "Next\n" :
		"<A HREF=\"$common_url@{[$curr_seg_num+1]}\">Next</A>\n";
	
	my $document_navbar =
		<<__endquote.
<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=10><TR>
 <TD>$prev_seg_html</TD><TD ALIGN="center">
__endquote

		join( ' | ', @seg_list_html ).

		<<__endquote;
 </TD><TD>$next_seg_html</TD>
</TR></TABLE>
__endquote

	$globals->body_prepend( [$document_navbar] );
	$globals->body_append( [$document_navbar] );
}

######################################################################

sub attach_document_header {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->site_prefs();

	my $title = $rh_prefs->{$PKEY_TITLE};
	my $author = $rh_prefs->{$PKEY_AUTHOR};
	my $created = $rh_prefs->{$PKEY_CREATED};
	my $updated = $rh_prefs->{$PKEY_UPDATED};
	my $segments = $rh_prefs->{$PKEY_SEGMENTS};
	
	my $curr_seg_num = $globals->current_user_vrp_element();
	$title .= $segments > 1 ? ": $curr_seg_num / $segments" : '';
	
	$globals->title( $title );

	$globals->body_prepend( <<__endquote );
<H2>@{[$globals->title()]}</H2>

<P>Author: $author<BR>
Created: $created<BR>
Updated: $updated</P>
__endquote
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

perl(1), CGI::WPM::Base, CGI::WPM::Globals, CGI::WPM::Static.

=cut
