#!/usr/bin/perl

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ASCIITable;
$loaded = 1;
print "ok 1\n";
$i=2;

$t = new Text::ASCIITable({alignHeadRow => 'center'});
ok($t->setCols(['Name','Description','Amount']));
ok($t->setColWidth('Description',22));
ok($t->addRow('Apple',"A fruit. (very tasty!)",4));
$t->addRow('Milk',"You get it from the cows, or the nearest shop.",2);
$t->addRow('Egg','Usually from birds.',6);
$t->addRow('Too wide','Thisisonelongwordthatismorethan22charactersandshouldbecutdownat22characters',1);
eval {
  $content = $t->draw();
};

if (!$@) {ok(undef)} else {ok(1)}

@arr = split(/\n/,$content);
for(@arr) {
  if (length($_) != $t->getTableWidth()) {
    $err = 1;
    last;
  }
}
ok($err);

if (length($arr[2]) == 46) {ok(undef);} else {ok(1);} # should be 46 chars wide
if (scalar(@arr) == 10) {ok(undef);} else {ok(1);} # should be 10 lines

sub ok{print(defined(shift)?"not ok $i\n":"ok $i\n");$i++;}
