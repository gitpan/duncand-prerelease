=head1 NAME

CGI::WPM::MultiPage - Demo of HTML::Application that resolves navigation for one 
level in the web site page hierarchy from a parent node to its children, 
encapsulates and returns its childrens' returned web page components, and can 
make a navigation bar to child pages.

=cut

######################################################################

package CGI::WPM::MultiPage;
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

	I<none>

=head2 Nonstandard Modules

	HTML::Application 0.4
	CGI::WPM::Base 0.4

=cut

######################################################################

use HTML::Application 0.4;
use CGI::WPM::Base 0.4;
@ISA = qw(CGI::WPM::Base);

######################################################################

=head1 SYNOPSIS

=head2 An example configuration file for a multiple-page website

	my $rh_preferences = { 
		page_header => <<__endquote,
	__endquote
		page_footer => <<__endquote,
	<P><EM>Sample Web Site was created and is maintained for personal use by 
	Darren Duncan.  All content and source code was 
	created by me, unless otherwise stated.  Content that I did not create is 
	used with permission from the creators, who are appropriately credited where 
	it is used and in the Works Cited section of this site.</EM></P>
	__endquote
		page_css_code => [
			'BODY {background-color: white; background-image: none}'
		],
		page_replace => {
			__graphics_directories__ => 'http://www.sampleweb.net/graphics_directories',
			__graphics_webring__ => 'http://www.sampleweb.net/graphics_webring',
		},
		vrp_handlers => {
			external => {
				wpm_module => 'CGI::WPM::Redirect',
				wpm_prefs => {},
			},
			frontdoor => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'frontdoor.html' },
			},
			intro => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'intro.html' },
			},
			whatsnew => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'whatsnew.html' },
			},
			timelines => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'timelines.html' },
			},
			indexes => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'indexes.html' },
			},
			cited => {
				wpm_module => 'CGI::WPM::MultiPage',
				wpm_subdir => 'cited',
				wpm_prefs => 'cited_prefs.pl',
			},
			mailme => {
				wpm_module => 'CGI::WPM::MailForm',
				wpm_prefs => {},
			},
			guestbook => {
				wpm_module => 'CGI::WPM::GuestBook',
				wpm_prefs => {
					custom_fd => 1,
					field_defn => 'guestbook_questions.txt',
					fd_in_seqf => 1,
					fn_messages => 'guestbook_messages.txt',
				},
			},
			links => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'links.html' },
			},
			webrings => {
				wpm_module => 'CGI::WPM::Static',
				wpm_prefs => { filename => 'webrings.html' },
			},
		},
		def_handler => 'frontdoor',
		menu_items => [
			{
				menu_name => 'Front Door',
				menu_path => '',
				is_active => 1,
			}, {
				menu_name => 'Welcome to SampleWeb',
				menu_path => 'intro',
				is_active => 1,
			}, {
				menu_name => "What's New",
				menu_path => 'whatsnew',
				is_active => 1,
			}, 1, {
				menu_name => 'Story Timelines',
				menu_path => 'timelines',
				is_active => 1,
			}, {
				menu_name => 'Issue Indexes',
				menu_path => 'indexes',
				is_active => 1,
			}, {
				menu_name => 'Works Cited',
				menu_path => 'cited',
				is_active => 1,
			}, {
				menu_name => 'Preview Database',
				menu_path => 'dbprev',
				is_active => 0,
			}, 1, {
				menu_name => 'Send Me E-mail',
				menu_path => 'mailme',
				is_active => 1,
			}, {
				menu_name => 'Guest Book',
				menu_path => 'guestbook',
				is_active => 1,
			}, 1, {
				menu_name => 'External Links',
				menu_path => 'links',
				is_active => 1,
			}, {
				menu_name => 'Webrings',
				menu_path => 'webrings',
				is_active => 1,
			},
		],
		menu_cols => 4,
	#	menu_colwid => 100,
		menu_showdiv => 0,
	#	menu_bgcolor => '#ddeeff',
		page_showdiv => 1,
	};

=head1 DESCRIPTION

This Perl 5 object class is part of a demonstration of HTML::Application in use.  
It is one of a set of "application components" that takes its settings and user 
input through HTML::Application and uses that class to send its user output.  
This demo module set can be used together to implement a web site complete with 
static html pages, e-mail forms, guest books, segmented text document display, 
usage tracking, and url-forwarding.  Of course, true to the intent of 
HTML::Application, each of the modules in this demo set can be used independantly 
of the others.

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

=head1 PUBLIC FUNCTIONS AND METHODS

=head2 main( GLOBALS )

You invoke this method to run the application component that is encapsulated by 
this class.  The required argument GLOBALS is an HTML::Application object that 
you have previously configured to hold the instance settings and user input for 
this class.  When this method returns then the encapsulated application will 
have finished and you can get its user output from the HTML::Application object.

=head1 PREFERENCES HANDLED BY THIS MODULE

I<This POD is coming when I get the time to write it.>

	vrp_handlers  # match wpm handler to a vrp
	def_handler   # if vrp undef, which handler?
	menu_items    # items in site menu, vrp for each
	menu_cols     # menu divided into n cols
	menu_colwid   # width of each col, in pixels
	menu_showdiv  # show dividers btwn menu groups?
	menu_bgcolor  # background for menu
	menu_showdiv  # show dividers btwn menu groups?
	page_showdiv  # do we use HRs to sep menu?

=head2 PROPERTIES OF ELEMENTS IN vrp_handlers HASH

	wpm_module  # wpm module making content
	wpm_subdir  # subdir holding wpm support files
	wpm_prefs   # prefs hash/fn we give to wpm mod

=head2 PROPERTIES OF ELEMENTS IN menu_items ARRAY

	menu_name  # visible name appearing in site menu
	menu_path  # vrp used in url for menu item
	is_active  # is menu item enabled or not?

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site global preferences:

# Keys for items in site page preferences:
my $PKEY_VRP_HANDLERS = 'vrp_handlers';  # match wpm handler to a vrp
my $PKEY_DEF_HANDLER  = 'def_handler';  # if vrp undef, which handler?
my $PKEY_MENU_ITEMS   = 'menu_items';  # items in site menu, vrp for each
my $PKEY_MENU_COLS    = 'menu_cols';  # menu divided into n cols
my $PKEY_MENU_COLWID  = 'menu_colwid';  # width of each col, in pixels
my $PKEY_MENU_SHOWDIV = 'menu_showdiv';  # show dividers btwn menu groups?
my $PKEY_MENU_BGCOLOR = 'menu_bgcolor';  # background for menu
my $PKEY_PAGE_SHOWDIV = 'page_showdiv';  # do we use HRs to sep menu?

# Keys for elements in $PKEY_VRP_HANDLERS hash:
my $HKEY_WPM_MODULE = 'wpm_module';  # wpm module making content
my $HKEY_WPM_SUBDIR = 'wpm_subdir';  # subdir holding wpm support files
my $HKEY_WPM_PREFS = 'wpm_prefs';  # prefs hash/fn we give to wpm mod

# Keys for elements in $PKEY_MENU_ITEMS array:
my $MKEY_MENU_NAME = 'menu_name';  # visible name appearing in site menu
my $MKEY_MENU_PATH = 'menu_path';  # vrp used in url for menu item
my $MKEY_IS_ACTIVE = 'is_active';  # is menu item enabled or not?

# Constant values used in this class go here:

######################################################################
# This is provided so CGI::WPM::Base->main() can call it.

sub main_dispatch {
	my $self = shift( @_ );

	$self->get_inner_wpm_content();  # puts in webpage of $globals

	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();

	if( $rh_prefs->{$PKEY_PAGE_SHOWDIV} ) {
		$globals->prepend_page_body( "\n<HR>\n" );
		$globals->append_page_body( "\n<HR>\n" );
	}

	if( ref( $rh_prefs->{$PKEY_MENU_ITEMS} ) eq 'ARRAY' ) {
		$self->attach_page_menu();
	}
}

######################################################################

sub get_inner_wpm_content {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $rh_prefs = $globals->get_prefs_ref();

	my $page_id = $globals->current_user_path_element();
	$page_id ||= $rh_prefs->{$PKEY_DEF_HANDLER};
	my $vrp_handler = $rh_prefs->{$PKEY_VRP_HANDLERS}->{$page_id};
	
	unless( ref( $vrp_handler ) eq 'HASH' ) {
		$globals->page_title( '404 Page Not Found' );

		$globals->set_page_body( <<__endquote );
<H2 ALIGN="center">@{[$globals->page_title()]}</H2>

<P>I'm sorry, but the page you requested, 
"@{[$globals->user_path_string()]}", doesn't seem to exist.  
If you manually typed that address into the browser, then it is either 
outdated or you misspelled it.  If you got this error while clicking 
on one of the links on this website, then the problem is likely 
on this end.  In the latter case...</P>

@{[$self->_get_amendment_message()]}
__endquote

		return( 1 );
	}
	
	my $wpm_context = $globals->make_new_context();
	$wpm_context->inc_user_path_level();
	$wpm_context->navigate_url_path( $page_id );
	$wpm_context->navigate_file_path( $vrp_handler->{$HKEY_WPM_SUBDIR} );
	$wpm_context->set_prefs( $vrp_handler->{$HKEY_WPM_PREFS} );

	my $wpm_mod_name = $vrp_handler->{$HKEY_WPM_MODULE};
	$wpm_context->call_component( $wpm_mod_name, 1 );

	if( my $msg = $wpm_context->get_error() ) {
		$globals->add_error( $msg );
	
		$globals->page_title( 'Error Getting Page' );

		$globals->set_page_body( <<__endquote );
<H2 ALIGN="center">@{[$globals->page_title()]}</H2>

<P>I'm sorry, but an error occurred while getting the requested
page.  We were unable to use the module that was supposed to 
generate the page content, named "$wpm_mod_name".</P>

@{[$self->_get_amendment_message()]}

<P>$msg</P>
__endquote

		$globals->add_no_error();
	
	} else {
		$globals->take_context_output( $wpm_context );
	}
}

######################################################################

sub attach_page_menu {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	
	my $menu_table = $self->make_page_menu_table();

	$globals->prepend_page_body( [$menu_table] );
	$globals->append_page_body( [$menu_table] );
}

######################################################################

sub make_menu_items_html {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};	
	my $rh_prefs = $globals->get_prefs_ref();
	my $ra_menu_items = $rh_prefs->{$PKEY_MENU_ITEMS};
	my @menu_html = ();
	
	foreach my $rh_curr_page (@{$ra_menu_items}) {
		if( ref( $rh_curr_page ) ne 'HASH' ) {
			$rh_prefs->{$PKEY_MENU_SHOWDIV} or next;
			push( @menu_html, undef );   # insert menu divider,
			next;                   
		}

		unless( $rh_curr_page->{$MKEY_IS_ACTIVE} ) {
			push( @menu_html, "$rh_curr_page->{$MKEY_MENU_NAME}" );
			next;
		}
		
		my $url = $globals->url_as_string( 
			$rh_curr_page->{$MKEY_MENU_PATH} );
		push( @menu_html, "<A HREF=\"$url\"".
			">$rh_curr_page->{$MKEY_MENU_NAME}</A>" );
	}
	
	return( @menu_html );
}

######################################################################
# This method currently isn't called by anything, but may be later.

sub make_page_menu_vert {
	my $self = shift( @_ );
	my @menu_items = $self->make_menu_items_html();
	my @menu_html = ();
	my $prev_item = undef;
	foreach my $curr_item (@menu_items) {
		push( @menu_html, 
			!defined( $curr_item ) ? "<HR>\n" : 
			defined( $prev_item ) ? "<BR>$curr_item\n" : 
			"$curr_item\n" );
		$prev_item = $curr_item;
	}
	return( '<P>'.join( '', @menu_html ).'</P>' );
}

######################################################################
# This method currently isn't called by anything, but may be later.

sub make_page_menu_horiz {
	my $self = shift( @_ );
	my @menu_items = $self->make_menu_items_html();
	my @menu_html = ();
	foreach my $curr_item (@menu_items) {
		defined( $curr_item ) or next;
		push( @menu_html, "$curr_item\n" );
	}
	return( '<P>'.join( ' | ', @menu_html ).'</P>' );
}

######################################################################

sub make_page_menu_table {
	my $self = shift( @_ );
	my $rh_prefs = $self->{$KEY_SITE_GLOBALS}->get_prefs_ref();
	my @menu_items = $self->make_menu_items_html();
	
	my $length = scalar( @menu_items );
	my $max_cols = $rh_prefs->{$PKEY_MENU_COLS};
	$max_cols <= 1 and $max_cols = 1;
	my $max_rows = 
		int( $length / $max_cols ) + ($length % $max_cols ? 1 : 0);

	my $colwid = $rh_prefs->{$PKEY_MENU_COLWID};
	$colwid and $colwid = " WIDTH=\"$colwid\"";
	
	my $bgcolor = $rh_prefs->{$PKEY_MENU_BGCOLOR};
	$bgcolor and $bgcolor = " BGCOLOR=\"$bgcolor\"";
	
	my @table_lines = ();
	
	push( @table_lines, "<TABLE BORDER=0 CELLSPACING=0 ".
		"CELLPADDING=10 ALIGN=\"center\">\n<TR>\n" );
	
	foreach my $col_num (1..$max_cols) {
		my $prev_item = undef;
		my @cell_lines = ();
		my @cell_items = splice( @menu_items, 0, $max_rows ) or last;
		foreach my $curr_item (@cell_items) {
			push( @cell_lines, 
				!defined( $curr_item ) ? "<HR>\n" : 
				defined( $prev_item ) ? "<BR>$curr_item\n" : 
				"$curr_item\n" );
			$prev_item = $curr_item;
		}
		push( @table_lines,
			"<TD ALIGN=\"left\" VALIGN=\"top\"$bgcolor$colwid>\n",
			@cell_lines, "</TD>\n" );
	}
	
	push( @table_lines, "</TR>\n</TABLE>\n" );

	return( join( '', @table_lines ) );
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

perl(1), HTML::Application, CGI::WPM::Base.

=cut
