package Text::ASCIITable;
# by Håkon Nessjøen <lunatic@skonux.net>

# BETA VERSION

@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.07';
use Exporter;
use strict;
use Carp;

# Determine if Text::Wrap is installed
my $hasWrap;
if (eval { require Text::Wrap }) { use Text::Wrap; $hasWrap=1; }
else { $hasWrap=0; }

=head1 NAME

Text::ASCIITable - Create a nice formatted table using ASCII characters. Nice, if you want to output dynamic
text to your console or other fixed-size displays.

=head1 SYNOPSIS

  use Text::ASCIITable;
  
  $t = new Text::ASCIITable;
  $t->setCols(['Nickname','Name']);
  $t->addRow('Lunatic-|','Håkon Nessjøen');
  $t->addRow('tesepe','William Viker');
  $t->addRow('espen','Espen Ursin-Holm');
  $t->addRow('mamikk','Martin Mikkelsen');
  $t->addRow('p33r','Espen A. Jütte');
  print $t->draw(); 
  

=head1 FUNCTIONS

=head2 new(options)

Initialize a new table. You can specify output-options. For more options, check out the usage for setOptions(name,value)

  Usage:
  $t = new Text::ASCIITable;
  
  Or with options:
  $t = new Text::ASCIITable({ hide_Lastline => 1, reportErrors => 0});

=cut

sub new {
  my $self = {tbl_cols => [],tbl_rows => [],tbl_align => {},options => $_[1] || { }};
  $self->{options}{reportErrors} = iif($self->{options}{reportErrors},1); # default setting
  $self->{options}{alignHeadRow} = iif($self->{options}{alignHeadRow},'left'); # default setting
  bless $self;
  return $self;
}

=head2 setCols(@cols)

Define the columns for the table(compare with <TH> in HTML). For example C<setCols(['Id','Nick','Name'])>.
B<Note> that you cannot add Cols after you have added a row.

=cut

sub setCols {
  my $self = shift;
  my $tmp = shift;
  do { $self->reperror("setCols needs an array"); return 1; } unless defined($tmp);
  my @cols = @{$tmp};
  do { $self->reperror("setCols needs an array"); return 1; } unless scalar(@cols) != 0;
  do { $self->reperror("Cannot edit cols at this state"); return 1; } unless scalar(@{$self->{tbl_rows}}) == 0;
  @{$self->{tbl_cols}} = @cols;
  return undef;
}

=head2 addCol($col)

Add a column to the columnlist. This still can't be done after you have added a row.

=cut

sub addCol {
  my ($self,$col) = @_;
  do { $self->reperror("addCol needs a string"); return 1; } unless defined($col);
  do { $self->reperror("Cannot add cols at this state"); return 1; } if (scalar(@{$self->{tbl_rows}}) != 0);
  push @{$self->{tbl_cols}},$col;
  return undef;
}

=head2 addRow(@collist)

Adds one row to the table. This must be an array of strings. If you defined 3 columns. This array must
have 3 items in it. And so on. Should be self explanatory. The strings can contain newlines.

=cut

sub addRow {
  my $self = shift;
  do { $self->reperror("Received too few columns"); return 1; } if scalar(@_) < scalar(@{$self->{tbl_cols}});
  do { $self->reperror("Received too many columns"); return 1; } if scalar(@_) > scalar(@{$self->{tbl_cols}});
  my (@in,@out,@lines,$max);

  # Word wrapping:
  if ($hasWrap) {
    foreach my $c (0..(scalar(@_)-1)) {
      my $width = $self->{tbl_width}{@{$self->{tbl_cols}}[$c]};
      if ($width) {
        $Text::Wrap::columns = $width;
        $in[$c] = wrap('', '', $_[$c]);
      } else {
        $in[$c] = $_[$c];
      }
    }
  } else { @in = @_; }

  # Multiline support:
  @lines = map { [ split(/\n/,$_) ] } @in;
  $max=0;
  foreach (@lines) {
    $max = scalar(@{$_}) if scalar(@{$_}) > $max;
  }
  foreach my $num (0..($max-1)) {
    my @tmp;
    foreach (@lines) {
      push @tmp,iif(@{$_}[$num],'');
    }
    push @out, [ @tmp ];
  }

  # Add row(s)
  push @{$self->{tbl_rows}}, @out;

  return undef;
}

=head2 alignCol($col,$direction)

Given a columnname, it aligns all data to the given direction in the table. This looks nice on numerical displays
in a column. The column names in the table will not be unaffected by the alignment. Possible directions is: left,
center and right. (Hint: It is often very useful to align numbers to the right, and text to the left.)

=cut

# backwardscompatibility, deprecated
sub alignColRight {
  my ($self,$col) = @_;
  do { $self->reperror("alignColRight is missing parameter(s)"); return 1; } unless defined($col);
  return $self->alignCol($col,'right');
}

sub alignCol {
  my ($self,$col,$direction) = @_;
  do { $self->reperror("alignCol is missing parameter(s)"); return 1; } unless defined($col) && defined($direction);
  do { $self->reperror("Could not find '$col' in columnlist"); return 1; } unless defined(&find($col,$self->{tbl_cols}));
  $self->{tbl_align}{$col} = $direction;

  return undef;
}

=head2 setColWidth($col,$width)

Wordwrapping. Set a max-width(in chars) for a column.

 Usage:
  $t->setColWidth('Description',30);

=cut

sub setColWidth {
  my ($self,$col,$width) = @_;
  do { $self->reperror("setColWidth is missing parameter(s)"); return 1; } unless defined($col) && defined($width);
  do { $self->reperror("Could not find '$col' in columnlist"); return 1; } unless defined(&find($col,$self->{tbl_cols}));
  do { $self->reperror("Text::Wrap not installed. Please install from CPAN"); return 1; } unless $hasWrap;
  $self->{tbl_width}{$col} = int($width);

  return undef;
}

# drawing etc, below

sub getColWidth {
  my ($self,$colname) = @_;
  my $pos = &find($colname,$self->{tbl_cols});
  my $maxsize = $self->count($colname);

  do { $self->reperror("Could not find '$colname' in columnlist"); return 1; } unless defined($pos);
  for my $row (@{$self->{tbl_rows}}) {
    $maxsize = $self->count(@{$row}[$pos]) if ($self->count(@{$row}[$pos]) > $maxsize);
  }

  # maxsize pluss the spaces on each side
  return $maxsize + 2;
}

=head2 getTableWidth()

If you need to know how wide your table will be before you draw it. Use this function.

=cut

sub getTableWidth {
  my $self = shift;
  my $totalsize = 1;
  for (@{$self->{tbl_cols}}) {
    $totalsize += $self->getColWidth($_) + 1;
  }
  return $totalsize;
}

sub drawLine {
  my ($self,$start,$stop,$line,$delim) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($stop);
  $line = defined($line) ? $line : '-'; 
  $delim = defined($delim) ? $delim : '+'; 

  my $contents;

  $contents = $start;

  for (my $i=0;$i < scalar(@{$self->{tbl_cols}});$i++) {
    my $offset = 0;
    $offset = length($start) - 1 if ($i == 0);
    $offset = length($stop) - 1 if ($i == scalar(@{$self->{tbl_cols}}) -1);

    $contents .= $line x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - $offset);

    $contents .= $delim if ($i != scalar(@{$self->{tbl_cols}}) - 1);
  }
  return $contents.$stop."\n";
}

=head2 setOptions(name,value)

Use this to set options like: hide_FirstLine,hide_HeadLine,hide_HeadRow,hide_LastLine,reportErrors,allowHTML or alignHeadRow.

  $t->setOptions('hide_HeadLine',1);

When B<allowHTML> is set to 1, it makes it possible to use this table in a HTML page where you want links/colors on the 
text inside the table. You can then use <B>hello</B> inside a row/columnname without the table-width to break apart.
When using Text::ASCIITable on webpages, remember to use <PRE> before and after the output of this table.

=cut

sub setOptions {
  my ($self,$name,$value) = @_;
  my $old = $self->{options}{$name} || undef;
  $self->{options}{$name} = $value;
  return $old;
}

sub drawRow {
  my ($self,$row,$isheader,$start,$stop,$delim) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($row);
  $isheader = &iif($isheader,0);
  $delim = &iif($delim,'|');

  my $contents = $start;
  for (my $i=0;$i<scalar(@{$row});$i++) {
    my $text = @{$row}[$i];

    if ($isheader != 1 && defined($self->{tbl_align}{@{$self->{tbl_cols}}[$i]})) {
      $contents .= ' '.$self->align(
                         $text,
                         &iif($self->{tbl_align}{@{$self->{tbl_cols}}[$i]},'left'),
                         $self->getColWidth(@{$self->{tbl_cols}}[$i])-2,
                         ($self->{options}{allowHTML}?0:1)
                       ).' ';
    } elsif ($isheader == 1) {
      $contents .= ' '.$self->align(
                         $text,
                         $self->{options}{alignHeadRow},
                         $self->getColWidth(@{$self->{tbl_cols}}[$i])-2,
                         ($self->{options}{allowHTML}?0:1)
                       ).' ';
    } else {
      $contents .= ' '.$self->align(
                         $text,
                         'left',
                         $self->getColWidth(@{$self->{tbl_cols}}[$i])-2,
                         ($self->{options}{allowHTML}?0:1)
                       ).' ';
    }
    $contents .= $delim if ($i != scalar(@{$row}) - 1);
  }
  return $contents.$stop."\n";
}

=head2 draw([@topdesign,@toprow,@middle,@middlerow,@bottom])

All the arrays containing the layout is optional. If you want to make your own "design" to the table, you
can do that by giving this method these arrays containing information about which characters to use
where.

=head3 Custom tables

The draw method takes C<5> arrays of strings to define the layout. The first, third and fifth is B<LINE>
layout and the second and fourth is B<ROW> layout. The C<fourth> parameter is repeated for each row in the table.

 $t->draw(<LINE>,<ROW>,<LINE>,<ROW>,<LINE>)

=over 4

=item LINE

Takes an array of C<4> strings. For example C<['|','|','-','+']>

=over 4

=item *

LEFT - Defines the left chars. May be more than one char.

=item *

RIGHT - Defines the right chars. May be more then one char.

=item *

LINE - Defines the char used for the line. B<Must be only one char>.

=item *

DELIMETER - Defines the char used for the delimeters. B<Must be only one char>.

=back

=item ROW

Takes an array of C<3> strings. You should not give more than one char to any of these parameters,
if you do.. it will probably destroy the output.. Unless you do it with the knowledge
of how it will end up. An example: C<['|','|','+']>

=over 4

=item *

LEFT - Define the char used for the left side of the table.

=item *

RIGHT - Define the char used for the right side of the table.

=item *

DELIMETER - Defines the char used for the delimeters.

=back

=back

Examples:

The easiest way:

 $t->draw();

Explanatory example:

 $t->draw( ['L','R','l','D'],  # LllllllDllllllR
           ['L','R','D'],      # L info D info R
           ['L','R','l','D'],  # LllllllDllllllR
           ['L','R','D'],      # L info D info R
           ['L','R','l','D']   # LllllllDllllllR
          );

Nice example:

 $t->draw( ['.','.','-','-'],   # .-------------.
           ['|','|','|'],       # | info | info |
           ['|','|','-','-'],   # |-------------|
           ['|','|','|'],       # | info | info |
           [' \\','/ ','_','|'] #  \_____|_____/
          ));

Nice example2:

 $t->draw( ['.=','=.','-','-'],   # .=-----------=.
           ['|','|','|'],         # | info | info |
           ['|=','=|','-','+'],   # |=-----+-----=|
           ['|','|','|'],         # | info | info |
           ["'=","='",'-','-']    # '=-----------='
          ));

=cut

sub draw {
  my $self = shift;
  my ($top,$toprow,$middle,$middlerow,$bottom) = @_;
  my ($tstart,$tstop,$tline,$tdelim) = defined($top) ? @{$top} : undef;
  my ($trstart,$trstop,$trdelim) = defined($toprow) ? @{$toprow} : undef;
  my ($mstart,$mstop,$mline,$mdelim) = defined($middle) ? @{$middle} : undef;
  my ($mrstart,$mrstop,$mrdelim) = defined($middlerow) ? @{$middlerow} : undef;
  my ($bstart,$bstop,$bline,$bdelim) = defined($bottom) ? @{$bottom} : undef;
  my $contents="";
  $contents .= $self->drawLine(&iif($tstart,'.'),&iif($tstop,'.'),$tline,$tdelim) unless $self->{options}{hide_FirstLine};
  $contents .= $self->drawRow($self->{tbl_cols},1,&iif($trstart,'|'),&iif($trstop,'|'),&iif($trdelim,'|')) unless $self->{options}{hide_HeadRow};
  $contents .= $self->drawLine(&iif($mstart,' >'),&iif($mstop,'< '),$mline,$mdelim) unless $self->{options}{hide_HeadLine};
  for (@{$self->{tbl_rows}}) {
    $contents .= $self->drawRow($_,0,&iif($mrstart,'|'),&iif($mrstop,'|'),&iif($mrdelim,'|'));
  }
  $contents .= $self->drawLine(&iif($bstart,"'"),&iif($bstop,"'"),$bline,$bdelim) unless $self->{options}{hide_LastLine};
  return $contents;
}

# nifty subs

# Replaces length() because of optional HTML stripping
sub count {
  my $self = shift;
  my $moo = shift;
  if ($self->{options}{allowHTML}) {
    $moo =~ s/<.+?>//g;
    return length($moo);
  }
  else {
    return length($moo);
  }
}

sub align {

  my ($self,$text,$dir,$length,$strict) = @_;

  if ($dir eq "right") {
    $text = (" " x ($length - $self->count($text))).$text;
    return substr($text,0,$length) if ($strict);
    return $text;
  } elsif ($dir eq "left") {
    $text = $text.(" " x ($length - $self->count($text)));
    return substr($text,0,$length) if ($strict);
    return $text;
  } elsif ($dir =~ /center/i) {
    my $left = ( $length - $self->count($text) ) / 2;
    # Someone tell me if this is matematecally totally wrong. :P
    $left = int($left) + 1 if ($left ne int($left) && $left > 0.4);
    my $right = int(( $length - $self->count($text) ) / 2);
    $text = (" " x $left).$text.(" " x $right);
    return substr($text,0,$length) if ($strict);
    return $text;
  }
}

sub reperror {
  my $self = shift;
  print STDERR Carp::shortmess(shift) if $self->{options}{reportErrors};
}
sub iif {
  return defined($_[0]) ? $_[0] : $_[1];
}
# Couldn't find a better way to search in an array, than to make this function. Please tell me the right way..
sub find {
  return undef unless defined $_[1];
  for (0..scalar(@{$_[1]})) {
    return $_ if @{$_[1]}[$_] eq $_[0];
  }
  return undef;
}


1;

__END__

=head1 REQUIRES

Exporter, Carp, Text::Wrap

=head1 AUTHOR

Håkon Nessjøen, lunatic@skonux.net

=head1 VERSION

Current version is 0.07.

=head1 COPYRIGHT

Copyright 2002-2003 by Håkon Nessjøen.
All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

