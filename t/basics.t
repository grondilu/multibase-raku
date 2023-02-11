#!/usr/bin/env raku
use lib <lib>;
use Multibase;
use Test;

constant @lines = "tests/basic.csv".IO.lines;

constant $input = @lines.head.split(/\,\s*/)[1].subst('"','',:g);

plan 2;

subtest "encoding", {
  for @lines[1..*]».split(/\,\s*/) {
    my ($encoding, $result) = .[0], .[1].subst: '"', '', :g;

    if $encoding eq <
      base58btc
      base16upper
      base32
      base32upper
      base32hex
      base32hexupper
      base64pad
      base64url
      base256emoji
    >.any {
      is Multibase::encode($input, Multibase::Encoding::«$encoding»), $result, $encoding;
    } else { skip "$encoding NYI"; }

  }
}
subtest "decoding", {
  skip 'TODO', @lines - 1 ;

}


# vi: ft=raku
