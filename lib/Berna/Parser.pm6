use Berna::Grammar;
use Berna::Action;
unit class Berna::Parser;

has @.types       = <String Boolean Number Void>;
has %.vars;
has %.functions   =
    :print{     :signature[<String>],           :return<Void>   },
    :toString{  :signature[<Number>],           :return<String> },
    :toNumber{  :signature[<String>],           :return<Number> },
    :concat{    :signature[<String String>],    :return<String> },
;
has $!last-statement-type;

method parse(Str $e) {
    my @*types               := @!types;
    my %*vars                := %!vars;
    my %*functions           := %!functions;
    my $*last-statement-type := $!last-statement-type;

    Berna::Grammar.parse($e, :actions(Berna::Action.new)).made
}

