package Text::ASCIITable::Wrap;

@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(wrap);
$VERSION = '0.1';
use Exporter;
use strict;
use Carp;

=head1 NAME

Text::ASCIITable::Wrap - Wrap text

=head1 SHORT DESCRIPTION

Make sure a text never gets wider than the specified width using wordwrap.

=head1 SYNOPSIS

  use Text::ASCIITable::Wrap qw{ wrap };
  print wrap(10,'This is a long line which will be cut down to several lines');

=head1 FUNCTIONS

=head2 wrap($text,$width[,$nostrict]) (exportable)

Wraps text at the specified width. Unless the $nostrict parameter is set, it
will cut down the word if a word is wider than $width. Also supports text with linebreaks.

=cut

sub wrap {
  my ($text,$width,$nostrict) = @_;
  Carp::shortmess('Missing required text or width parameter.') if (!defined($text) || !defined($width));
  my $result='';
  for (split(/\n/,$text)) {
    $result .= _wrap($_,$width,$nostrict)."\n";
  }
  chop($result);
  return $result;
}

sub _wrap {
  my ($text,$width,$nostrict) = @_;
  my @result;
  my $line='';
  my $num=0;
  for (split(/ /,$text)) {
    if ($num == 0) {
      if (length($_) > $width) {
        push @result, defined($nostrict) ? $_ : substr($_,0,$width); # kutt ned bredden
        $num=0;
        $line='';
      } else {
        $line = $_;
        if (length($_) + 1 >= $width) {
          push @result,$line;
          $num=0;
        } else {
          $num++;
        }
      }
    } else {
      if (length($line) + 1 + length($_) > $width) {
        push @result,$line;
        $line = $_;
        if (length($_)+1 >= $width) {
          push @result, defined($nostrict) ? $_ : substr($_,0,$width); # tilfelle den er for lang
          $num=0;
        } else {
          $num++;
        }
      } else {
        $line .= ' '.$_;
	$num++;
      }
    }
  }
  push @result,$line if $line ne '';
  return join("\n",@result);
}


1;

__END__

=head1 REQUIRES

Exporter, Carp

=head1 AUTHOR

Håkon Nessjøen, lunatic@cpan.org

=head1 VERSION

Current version is 0.1.

=head1 COPYRIGHT

Copyright 2002-2003 by Håkon Nessjøen.
All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Text::ASCIITable

=cut

