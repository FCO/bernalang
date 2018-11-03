#!/usr/bin/env perl6

use Grammar::Tracer;
grammar Berna {
    token TOP($*INDENT = "")        { \s* <line>* %% \n+ \s* || <error("syntax not recognized")> }
    token line                      { ^^ <.indent> <statement> \h* $$ }
    token indent                    { $*INDENT }
    proto token control             { * }
    token control:sym<If>           { <sym> \h+ }
    token control:sym<For>          { <sym> \h+ }
    token control:sym<While>        { <sym> \h+ }
    proto token declare             { * }
    token declare:sym<var>          {
        <type-name> \h+
        <name>
        {
            %*vars{ $<name> } = $<type-name>.Str;
            $*last-statement-type = $<type-name>.Str
        }
        [ \h+ <statement> ]?
    }
    token declare:sym<func>         { <decl-func(%*vars.clone, @*types.clone, %*functions.clone)> }
    proto token statement           { * }
    token statement:sym<decl>       { <declare> }
    token statement:sym<value>      { <value-ret> }
    proto token value-ret           { * }
    token value-ret:sym<val>        { <value> }
    token value-ret:sym<call-fun>   {
        <func-name> \h+
        {}
        <arg-list(%*functions{$<func-name>.Str}<signature>)>
        { $*last-statement-type = %*functions{$<func-name>.Str}<return> }
    }
    token value-ret:sym<var>        {
        { say %*vars }
        <var-name>
        {
            $*last-statement-type = %*vars{ $<var-name>.Str }
        }
    }
    token decl-func(%*vars, @*types, %*functions)       {
        :my $*last-statement-type;
        <func-proto> \n
        <new-indent> {}
        <body($<new-indent>.Str)>
        {
            self.error("function $<func-proto><name> should return $<func-proto><type-name> but is returning $*last-statement-type")
                unless $*last-statement-type eq $<func-proto><type-name>.Str
        }
    }
    token new-indent                { <.indent> \h+ || <error("error on indentation")> }
    token pair-args(@signature)     {
        <type-name> \h+
        <name> {
            @signature.push: $<type-name>.Str;
            %*vars{$<name>.Str} = $<type-name>.Str
        }
    }
    token func-proto                {
        <func-keyword> \h+
        [
            <type-name> || error("invalid type")
        ]
        \h+
        [
            || <name>
            || <error("invalid function name")>
        ]
        [
            \h+
            :my @signature;
            || <pair-args(@signature)>* % \h+ { %*functions{ $<name>.Str }<signature> = @signature.clone}
            || <error("wrong arguments on function $<name>")>
        ]?
    }
    token func-keyword              { "Function" }
    token body($*INDENT)            {
        <statement>
        [\n <line>+ % \n+]?
    }
    token arg-list(@sig)            { <wanted(@sig.shift)>+ % \h+}
    token wanted($*wanted)          { <value-ret>}
    proto token value               { * }
    token value:sym<num>            { <.want("Number")> \d+ { $*last-statement-type = "Number" } }
    token value:sym<sstr>           { <.want("String")> "'" ~ "'" $<str>=<-[']>* { $*last-statement-type = "String" } }
    token value:sym<dstr>           { <.want("String")> '"' ~ '"' <str>? { $*last-statement-type = "String" } }
    token str                       { <str-part>* }
    proto token str-part            { * }
    token str-part:sym<str>         { <-[$"]>+ }
    token str-part:sym<var>         {
        :my $*wanted = "String";
        '$' [ <var-name> || <error("Variable wasn't declared")> ]
    }
    token name                      {
        [
            || <.lower>
            || <error("name must start with lower case letter")>
        ]
        <.alnum>*
    }
    token type-name                 { << @*types >> }
    token var                       {
        :my @vars = %*vars.keys;
        << @vars >>
    }
    token var-name {
        <var>
        {
            self.error("wanted $*wanted but got variable of type %*vars{$<var>.Str}")
                if $*wanted.defined and %*vars{$<var>.Str} ne $*wanted;
        }
    }
    token func {
        :my @functions = %*functions.keys;
        << @functions >>
    }
    token func-name {
        <func>
        {
            self.error("wanted $*wanted but got a functions that returns %*functions{$<func>.Str}<return>")
                if $*wanted.defined and %*functions{$<func>.Str}<return> ne $*wanted;
        }
    }

    token want(Str $want) {
        || <?{ not $*wanted.defined or  $want eq $*wanted }>
        || <error("wanted $want but got $*wanted")>
    }
    method error($msg) {
        my $parsed-so-far = self.target.substr(0, self.pos);
        my $not-parsed = self.target.substr(self.pos, min self.target.index("\n", self.pos) - self.pos, self.pos + 15);
        my @lines = $parsed-so-far.lines;
        note "\nCompiling ERROR on line @lines.elems():\n";
        note "$msg: \o033[32m@lines[*-1].trim-leading()\o033[33m⏏\o033[31m$not-parsed\o033[m";
        exit 1;
    }
}

subset Code of Str;
my @*types       = <String Boolean Number>;
my %*vars;
my %*functions   =
    :print{     :signature[<String>],   :return<Void>},
    :toString{  :signature[Str],        :return<String>},
    :toNumber{  :signature[Str],        :return<Number>},
;
my $*last-statement-type;

multi MAIN(Code :$e!) {
    say Berna.parse: $e
}

multi MAIN(*@file) {
    say Berna.parsefile: @file
}
