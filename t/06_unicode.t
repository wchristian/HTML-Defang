#!/usr/bin/perl -w

BEGIN { do '/home/mod_perl/hm/ME/FindLibs.pm'; }

use utf8;
use Test::More tests => 9;
use HTML::Defang;
use Encode;
use Devel::Peek;
use strict;

my ($Res, $H);
my ($DefangString, $CommentStartText, $CommentEndText) = ('defang_', '', '');

#################################
#  Check unicodeness is preserved despite internal non-unicode magic
#################################

my $Defang = HTML::Defang->new(
  tags_to_callback => [ qw(a p) ],
  tags_callback => sub {
    my ($Context, $Defang, $Angle, $Tag, $IsEndTag, $AttributeHash, $AttributesEnd, $HtmlR, $OutR) = @_;
    if ($Tag eq 'a' && !$IsEndTag) {
      ok(Encode::is_utf8(${$AttributeHash->{href}}), "attr is unicode");
      is(${$AttributeHash->{href}}, 'http://blah.com/福', "attr unicode is correct");
      ${$AttributeHash->{href}} = 'http://blah.com/ø';
      ok(Encode::is_utf8(${$AttributeHash->{href}}), "attr is unicode2");
    } elsif ($Tag eq 'p' && !$IsEndTag) {
      ok(Encode::is_utf8($$HtmlR), "html ref is unicode");
      ok($$HtmlR =~ /\G(?=岡)/gc, "html ref unicode is correct");
    }
    return 1;
  }
);
$H = <<EOF;
<p>岡</p>
<a href="http://blah.com/福">non-english href</a>
EOF
ok(Encode::is_utf8($H), "input is unicode");
$Res = $Defang->defang($H);
ok(Encode::is_utf8($Res), "output is unicode");
like($Res, qr{^<!--defang_p-->岡<!--/defang_p-->}, "defang preserves unicode");
like($Res, qr{^<!--defang_a defang_href="http://blah\.com/ø"-->non-english href<!--/defang_a-->}m, "defang preserves unicode2");
