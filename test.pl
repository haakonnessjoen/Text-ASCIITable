#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$t = new Text::ASCIITable;
print defined($t->setCols(['id','nick'])) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->addCol('name')) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->alignColRight('id')) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->alignColRight('nick')) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->addRow('1','Lunatic-|','Håkon Nessjøen')) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
$t->addRow('2','tesepe','William Viker');
$t->addRow('3','espen','Espen Ursin-Holm');
$t->addRow('4','bonde','Martin Mikkelsen');
eval {
$alerted=0;
local $SIG{'__WARN__'} = sub { if ($alerted == 0) { print "not ok $i\n"; $alerted=1; warn $_[0]; } };
local $SIG{'__DIE__'} = sub { if ($alerted == 0) { print "not ok $i\n"; $alerted=1; warn $_[0]; } };
$content = $t->draw( ['.','.','-','-'],
                ['-'.'-'],
                ['|','|','-','-'],
                [' \\','/ ','_','|']
              );
print "ok $i\n" if ($alerted == 0);
};
if (!$@) {
"ok ".$i."\n"
} else {
"not ok ".$i."\n";
}
$i++;
my @arr = split(/\n/,$content);
if (length(@arr[0]) == $t->getTableWidth()) {
  print "ok ".$i."\n"; $i++;
} else {
  print "not ".$i."\n";
}
