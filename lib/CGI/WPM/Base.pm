=head1 NAME

CGI::WPM::Base - Demo of HTML::Application that is subclassed by 7 other demos.

=cut

######################################################################

package CGI::WPM::Base;
require 5.004;

# Copyright (c) 1999-2001, Darren R. Duncan. All rights reserved. This module is
# free software; you can redistribute it and/or modify it under the same terms as
# Perl itself.  However, I do request that this copyright information remain
# attached to the file.  If you modify this module and redistribute a changed
# version then please attach a note listing the modifications.

use strict;
use vars qw($VERSION);
$VERSION = '0.4';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	HTML::Application 0.4

=cut

######################################################################

use HTML::Application 0.4;

######################################################################

=head1 SYNOPSIS
	
=head2 What are the subclasses of this:

CGI::WPM::GuestBook, CGI::WPM::MailForm, CGI::WPM::MultiPage, CGI::WPM::Redirect, 
CGI::WPM::SegTextDoc, CGI::WPM::Static, and CGI::WPM::Usage.

=head2 How you pass extra Globals-type info to subclasses of this that need it:

	# Note that $globals is an HTML::Application object.
	# Code like this goes in your startup shell.

	my $site_extras = $globals->get_misc_objects_ref();
	$site_extras->{smtp_host} = 'mail.aardvark.net';  # defaults to 'localhost'
	$site_extras->{smtp_timeout} = 30;  # that's also the default
	$site_extras->{site_title} = 'Aardvark On The Range';
	$site_extras->{owner_name} = 'Tony Simons';
	$site_extras->{owner_email} = 'tony@aardvark.net';
	$site_extras->{owner_em_vrp} = '/contact/us';

	# And below that you can call_component() on subclasses.
	# The above global-type settings complement the "preferences" below and 
	# in the subclasses, but for these mods they don't live in the preferences.

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

	amend_msg  # personalized html appears on error page instead of subc action

	page_body    # if defined, no subclass is used and this literal used instead
	page_header  # content goes above our subclass's
	page_footer  # content goes below our subclass's
	page_title   # title for this document
	page_author  # author for this document
	page_meta    # meta tags for this document
	page_css_src   # stylesheet urls to link in
	page_css_code  # css code to embed in head
	page_body_attr # params to put in <BODY>
	page_replace   # replacements to perform

=head1 METHOD TO OVERRIDE BY SUBCLASSES

	main_dispatch() -- their version of main(), which is handled in Base

=head1 PRIVATE METHODS FOR USE BY SUBCLASSES

I<This POD is coming when I get the time to write it.>

	_set_to_init_error_page()
	_get_amendment_message()

	_smtp_host()
	_smtp_timeout()
	_site_title()
	_site_owner_name()
	_site_owner_email()
	_site_owner_email_vrp()
	_site_owner_email_html()

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_SITE_GLOBALS = 'site_globals';  # hold global site values

# Keys for items in site global preferences:
my $PKEY_AMEND_MSG = 'amend_msg';  # personalized html appears on error page

# Keys for items in site page preferences:
my $PKEY_PAGE_BODY = 'page_body';  # if defined, use literally *as* content

my $PKEY_PAGE_HEADER = 'page_header'; # content goes above our subclass's
my $PKEY_PAGE_FOOTER = 'page_footer'; # content goes below our subclass's
my $PKEY_PAGE_TITLE = 'page_title';  # title for this document
my $PKEY_PAGE_AUTHOR = 'page_author';  # author for this document
my $PKEY_PAGE_META = 'page_meta';  # meta tags for this document
my $PKEY_PAGE_CSS_SRC = 'page_css_src';  # stylesheet urls to link in
my $PKEY_PAGE_CSS_CODE = 'page_css_code';  # css code to embed in head
my $PKEY_PAGE_BODY_ATTR = 'page_body_attr';  # params to put in <BODY>
my $PKEY_PAGE_REPLACE = 'page_replace';  # replacements to perform

# These properties are used in conjunction with sending e-mails.
my $GKEY_SMTP_HOST    = 'smtp_host';    # what computer sends our mail
my $GKEY_SMTP_TIMEOUT = 'smtp_timeout'; # how long wait for mail send
my $GKEY_SITE_TITLE   = 'site_title';   # name of site
my $GKEY_OWNER_NAME   = 'owner_name';   # name of site's owner
my $GKEY_OWNER_EMAIL  = 'owner_email';  # e-mail of site's owner
my $GKEY_OWNER_EM_VRP = 'owner_em_vrp'; # vrp for e-mail page

# Constant values used in this class go here:

my $DEF_SMTP_HOST = 'localhost';
my $DEF_SMTP_TIMEOUT = 30;
my $DEF_SITE_TITLE = 'Untitled Website';

######################################################################

sub main {
	my ($class, $globals) = @_;
	my $self = bless( {}, ref($class) || $class );

	UNIVERSAL::isa( $globals, 'HTML::Application' ) or 
		die "initializer is not a valid HTML::Application object";

	$self->{$KEY_SITE_GLOBALS} = $globals;

	if( $globals->get_error() ) {  # prefs not open
		$self->_set_to_init_error_page();
		return( 0 );
	}

	my $body = $globals->pref( $PKEY_PAGE_BODY );
	if( defined( $body ) ) {
		$globals->set_page_body( $body );
	} else {
		$self->main_dispatch();
	}
	
	my $rh_prefs = $globals->get_prefs_ref();
		# note that we don't see parent prefs here, only current level

	$globals->prepend_page_body( $rh_prefs->{$PKEY_PAGE_HEADER} );
	$globals->append_page_body( $rh_prefs->{$PKEY_PAGE_FOOTER} );

	$globals->page_title() or $globals->page_title( $rh_prefs->{$PKEY_PAGE_TITLE} );
	$globals->page_author() or $globals->page_author( $rh_prefs->{$PKEY_PAGE_AUTHOR} );
	
	if( ref( my $rh_meta = $rh_prefs->{$PKEY_PAGE_META} ) eq 'HASH' ) {
		@{$globals->get_page_meta_ref()}{keys %{$rh_meta}} = values %{$rh_meta};
	}	

	if( defined( my $css_urls_pref = $rh_prefs->{$PKEY_PAGE_CSS_SRC} ) ) {
		push( @{$globals->get_page_style_sources_ref()}, 
			ref($css_urls_pref) eq 'ARRAY' ? @{$css_urls_pref} : () );
	}
	if( defined( my $css_code_pref = $rh_prefs->{$PKEY_PAGE_CSS_CODE} ) ) {
		push( @{$globals->get_page_style_code_ref()}, 
			ref($css_code_pref) eq 'ARRAY' ? @{$css_code_pref} : () );
	}

	if( ref(my $rh_body = $rh_prefs->{$PKEY_PAGE_BODY_ATTR}) eq 'HASH' ) {
		@{$globals->get_page_body_attributes_ref()}{keys %{$rh_body}} = 
			values %{$rh_body};
	}

	$globals->search_and_replace_page_body( $rh_prefs->{$PKEY_PAGE_REPLACE} );
}

######################################################################

# subclass should have their own of these
sub main_dispatch {
	my $self = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( 'Web Page For Users' );

	$globals->set_page_body( <<__endquote );
<H2 ALIGN="center">@{[$globals->page_title()]}</H2>

<P>This web page has been generated by CGI::WPM::Base, which is 
copyright (c) 1999-2001, Darren R. Duncan.  This Perl Class 
is intended to be subclassed before it is used.</P>

<P>You are reading this message because either no subclass is in use 
or that subclass hasn't declared the main_dispatch() method.</P>
__endquote
}

######################################################################
# This is meant to be called after the global "is error" is set

sub _set_to_init_error_page {
	my ($self) = @_;
	my $globals = $self->{$KEY_SITE_GLOBALS};

	$globals->page_title( 'Error Initializing Page Maker' );

	$globals->set_page_body( <<__endquote );
<H2 ALIGN="center">@{[$globals->page_title()]}</H2>

<P>I'm sorry, but an error has occurred while trying to initialize 
a required program module, "@{[ref($self)]}".  The file that 
contains its preferences couldn't be opened.</P>  

@{[$self->_get_amendment_message()]}

<P>Details: @{[$globals->get_error()]}</P>
__endquote

	$globals->add_no_error();
}

######################################################################

sub _get_amendment_message {
	my ($self) = shift( @_ );
	my $globals = $self->{$KEY_SITE_GLOBALS};
	return( $globals->pref( $PKEY_AMEND_MSG ) || <<__endquote );
<P>This should be temporary, the result of a transient server problem
or a site update being performed at the moment.  Click 
@{[$globals->recall_html('here')]} to automatically try again.  
If the problem persists, please try again later, or send an
@{[$self->_site_owner_email_html('e-mail')]}
message about the problem, so it can be fixed.</P>
__endquote
}

######################################################################

sub _smtp_host {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_SMTP_HOST} = $new_value;
	}
	return( $site_extras->{$GKEY_SMTP_HOST} || $DEF_SMTP_HOST );
}

sub _smtp_timeout {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_SMTP_TIMEOUT} = $new_value;
	}
	return( $site_extras->{$GKEY_SMTP_TIMEOUT} || $DEF_SMTP_TIMEOUT );
}

sub _site_title {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_SITE_TITLE} = $new_value;
	}
	return( $site_extras->{$GKEY_SITE_TITLE} || $DEF_SITE_TITLE );
}

sub _site_owner_name {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_OWNER_NAME} = $new_value;
	}
	return( $site_extras->{$GKEY_OWNER_NAME} );
}

sub _site_owner_email {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_OWNER_EMAIL} = $new_value;
	}
	return( $site_extras->{$GKEY_OWNER_EMAIL} );
}

sub _site_owner_email_vrp {
	my ($self, $new_value) = @_;
	my $site_extras = $self->{$KEY_SITE_GLOBALS}->get_misc_objects_ref();
	if( defined( $new_value ) ) {
		$site_extras->{$GKEY_OWNER_EM_VRP} = $new_value;
	}
	return( $site_extras->{$GKEY_OWNER_EM_VRP} );
}

sub _site_owner_email_html {
	my ($self, $visible_text) = @_;
	$visible_text ||= 'e-mail';
	my $globals = $self->{$KEY_SITE_GLOBALS};
	my $owner_vrp = $self->_site_owner_email_vrp();
	my $owner_email = $self->_site_owner_email();
	return( $owner_vrp ? '<A HREF="'.$globals->url_as_string( 
		$owner_vrp ).'">'.$visible_text.'</A>' : '<A HREF="mailto:'.
		$owner_email.'">'.$visible_text.'</A> ('.$owner_email.')' );
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

perl(1), HTML::Application, CGI::WPM::GuestBook, CGI::WPM::MailForm, 
CGI::WPM::MultiPage, CGI::WPM::Redirect, CGI::WPM::SegTextDoc, CGI::WPM::Static, 
and CGI::WPM::Usage.

=cut
