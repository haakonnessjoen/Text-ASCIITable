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
print defined($t->setCols(['Name','Description','Amount'])) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->setColWidth('Description',22)) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->addRow('Apple',"A fruit. (very tasty!)",4)) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
print defined($t->alignCol('Amount','right')) ? "not ok ".$i."\n" : "ok ".$i."\n"; $i++;
$t->addRow('Milk',"You get it from the cows, or the nearest shop.","2 (L)");
$t->addRow('Egg','Usually from birds.',6);
eval {
  $content = $t->draw();
};
if (!$@) {
  print "ok ".$i."\n"
} else {
  print "not ok ".$i."\n";
}
$i++;
@arr = split(/\n/,$content);
$err=0;
for(@arr) {
  if (length($_) != $t->getTableWidth()) {
    $err = 1;
    last;
  }
}
if ($err) {
  print "not ".$i."\n"; $i++;
} else {
  print "ok ".$i."\n"; $i++;
}
if (scalar(@arr) == 10) {
  print "ok ".$i."\n";
} else {
  print "not ".$i."\n";
}

