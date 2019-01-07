use Berna::Grammar;
use Berna::Action;
unit class Berna::Parser;

has $.debug       = False;
has @.types       = <String Boolean Number Void>;
has %.vars;
has %.functions   =
    :print{     :signature[<String>],           :return<Void>   },
    :toString{  :signature[<Number>],           :return<String> },
    :toBoolean{ :signature[<Number>],           :return<Boolean>},
    :toNumber{  :signature[<String>],           :return<Number> },
    :concat{    :signature[<String String>],    :return<String> },
    :sum{       :signature[<Number Number>],    :return<Number> },
    :sub{       :signature[<Number Number>],    :return<Number> },
    :mul{       :signature[<Number Number>],    :return<Number> },
    :div{       :signature[<Number Number>],    :return<Number> },
    :equal{     :signature[<Number Number>],    :return<Boolean>},
    :not{       :signature[<Boolean>],          :return<Boolean>},
;
has $!last-statement-type;

method parse(Str $e) {
    my @*types               := @!types;
    my %*vars                := %!vars;
	my %*scope-vars			 := SetHash.new;
    my %*functions           := %!functions;
    my $*last-statement-type := $!last-statement-type;

    my $match = Berna::Grammar.parse: $e, :actions(Berna::Action.new);
	if $!debug {
		note "MATCH:";
		note $match;
		note "------------";
	}
	$match.?made
}

