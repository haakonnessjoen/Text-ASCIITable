use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Text::ASCIITable',
    'VERSION_FROM'	=> 'ASCIITable.pm', # finds $VERSION
    'ABSTRACT'		=> 'Prints nice formatted text-tables',
    'PREREQ_PM'		=> {	
				'Text::Wrap'	=> '2001.0131'
			   }
);
