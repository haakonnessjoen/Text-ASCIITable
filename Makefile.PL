use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Text::ASCIITable',
    'VERSION_FROM'	=> 'ASCIITable.pm', # finds $VERSION
    'ABSTRACT'		=> 'Prints nice formatted text-tables',
    'dist' => {
	       PREOP => 'pod2text ASCIITable.pm > $(DISTVNAME)/README',
	       DIST_DEFAULT => 'all tardist',
	       COMPRESS => 'gzip -9f'
	      },

);
