use Grammar::Tracer;
grammar Berna {
    token ws                        { \h* }
    rule  TOP($*INDENT = "")        { <line>* %% \n+ }
    token indent                    { $*INDENT }
    token line                      { ^^ <.indent> <pline> $$ }
    token pline                     { <statement> | <decl> }
    proto rule statement            { * }
    rule  statement:sym<value>      {<value>}
    rule  statement:sym<var-dec>    {<type> <name> { @*vars.push: $<name>.Str } <?> <statement>?}
    token statement:sym<var>        { <var-name> }
    token statement:sym<call-fun>   { <func-name> \h+ <arg-list> }
    token var-name                  { @*vars }
    token func-name                 { @*functions }
    token pair-args                 { <type> \h+ <name> { @*vars.push: $<name>.Str } }
    proto rule decl                 { * }
    token decl:sym<func>            { <func-proto(@*vars, @*types)> \n <body> }
    token func-proto(@vars, @types) {
        'Function' \h+
        <type> \h+
        <name> {
            @*functions.push: $<name>.Str
        } \h+
        :my @*vars  = |@vars;
        :my @*types = |@types;
        <pair-args>*
    }
    token body {
        $<new-indent> = \h+
        <pline>
        :my $*INDENT = $<new-indent>;
        [
            \n
            ^^ <.indent> <pline> $$
        ]*
    }
    token arg-list                  {<statement>+ % " "+}
    proto token value               { * }
    token value:sym<num>            { \d+ }
    token value:sym<str>            { "'" ~ "'" <str>? }
    token str                       { <str-part>* }
    proto token str-part            { * }
    token str-part:sym<str>         { <-[$']>+ }
    token str-part:sym<var>         { '$' [<var-name> || <name> {fail "Variable $<name> wasn't declared"} ] }
    token name                      { <.lower> <.alnum>* }
    token type                      { @*types }
}

class Berna::Action {
    method TOP($/)                       { make $<line>>>.made.join }
    method line($/)                      { make $<pline>.made ~ "\n" }
    method pline($/)                     { make $<statement>.made // $<decl>.made }
    method statement:sym<value>($/)      { make $<value>.made }
    method statement:sym<var-dec>($/)    { make "let { $<name>.made } { " = $_" with $<statement>.made }" }
    method statement:sym<var>($/)        { make $<var-name>.made }
    method statement:sym<call-fun>($/)   { make $<func-name>.made ~ "( { $<arg-list>.made } )" }
    method var-name($/)                  { make $/.Str }
    method func-name($/)                 { make $/.Str }
    method pair-args($/)                 { make $<name>.made }
    method decl:sym<func>($/)            { make "{ $<func-proto>.made }\n\{ {$<body>.made} \}" }
    method func-proto($/)                { make "function { $<name>.made }({ $<pair-args>>>.made.join: ", " })" }
    method body($/)                      { make $<pline>>>.made }
    method arg-list($/)                  { make $<statement>>>.made.join: ", " }
    method value:sym<num>($/)            { make $/.Num }
    method value:sym<str>($/)            { make "`{ $<str>.made }`" }
    method str($/)                       { make $<str-part>>>.made.join }
    method str-part:sym<str>($/)         { make $/.Str }
    method str-part:sym<var>($/)         { make "\$\{{$<name>.made}\}" }
    method name($/)                      { make $/.Str }
    method type($/)                      { make $/.Str }
}

my @*types       = <String Boolean Number>;
my @*vars;
my @*functions   = <print>;

say Berna.parsefile(@*ARGS, actions => Berna::Action).made
