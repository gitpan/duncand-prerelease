use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'duncand-prerelease',
	VERSION => 0.4,
	PREREQ_PM => {
		'HTML::Application' => 0.4,
		'HTML::FormTemplate' => 2.0,
	},
);
