package Text::ASCIITable;
# by Håkon Nessjøen <lunatic@skonux.net>

@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.06';
use Exporter;
use strict;
use Carp;
use Text::Aligner;

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
  $self->{options}{reportErrors} = 1; # default setting
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
        @in[$c] = wrap('', '', @_[$c]);
      } else {
        @in[$c] = @_[$c];
      }
    }
  } else { @in = @_; }

  # Multiline support:
  @lines = map { [ split(/\n/,$_) ] } @in;
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
  my $maxsize = length($colname);

  do { $self->reperror("Could not find '$colname' in columnlist"); return 1; } unless defined($pos);
  for my $row (@{$self->{tbl_rows}}) {
    $maxsize = length(@{$row}[$pos]) if (length(@{$row}[$pos]) > $maxsize);
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

Use this to set options like: hide_FirstLine,hide_HeadLine,hide_HeadRow,hide_LastLine.

  $t->setOptions('hide_HeadLine',1);

=cut

sub setOptions {
  my ($self,$name,$value) = @_;
  my $old = $self->{options}{$name} || undef;
  $self->{options}{$name} = $value;
  return $old;
}

sub drawRow {
  my ($self,$row,$allowalign,$start,$stop,$delim) = @_;
  do { $self->reperror("Missing reqired parameters"); return 1; } unless defined($row);
  $allowalign = &iif($allowalign,1);
  $delim = &iif($delim,'|');

  my $contents = $start;
  for (my $i=0;$i<scalar(@{$row});$i++) {
    my $text = @{$row}[$i];

    if ($allowalign == 1 && defined($self->{tbl_align}{@{$self->{tbl_cols}}[$i]})) {
      my $align = Text::Aligner->new(&iif($self->{tbl_align}{@{$self->{tbl_cols}}[$i]},'left'));
      $align->alloc('-' x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - 2));
      $contents .= ' '.$align->justify($text).' ';
    } else {
      my $align = Text::Aligner->new('left');
      $align->alloc('-' x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - 2));
      $contents .= ' '.$align->justify($text).' ';
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
  $contents .= $self->drawRow($self->{tbl_cols},0,&iif($trstart,'|'),&iif($trstop,'|'),&iif($trdelim,'|')) unless $self->{options}{hide_HeadRow};
  $contents .= $self->drawLine(&iif($mstart,' >'),&iif($mstop,'< '),$mline,$mdelim) unless $self->{options}{hide_HeadLine};
  for (@{$self->{tbl_rows}}) {
    $contents .= $self->drawRow($_,1,&iif($mrstart,'|'),&iif($mrstop,'|'),&iif($mrdelim,'|'));
  }
  $contents .= $self->drawLine(&iif($bstart,"'"),&iif($bstop,"'"),$bline,$bdelim) unless $self->{options}{hide_LastLine};
  return $contents;
}

# nifty subs

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

Exporter, Carp, Text::Aligner, Text::Wrap

=head1 AUTHOR

Håkon Nessjøen, lunatic@skonux.net

=head1 COPYRIGHT

Copyright 2002-2003 by Håkon Nessjøen.
All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
