#use Grammar::Tracer;
unit grammar Berna::Grammar;
token TOP($*INDENT = "")        { \s* <line>* %% \n+ \s* || <error("syntax not recognized")> }
token line                      { ^^ <.indent> <statement> \h* <unexpected-data>? $$ }
token unexpected-data           { \S+ && <error("unexpected data")> }
token indent                    { $*INDENT }
proto token control             { * }
token control:sym<If>           {
	:my %*scope-vars := SetHash.new;
	<sym> \h+ <wanted("Boolean")> \n
    <new-indent>{}
    <body($<new-indent>.Str)>
	{
        $*last-statement-type = "Void"
	}
}
token control:sym<For>          {
	:my %*scope-vars := SetHash.new;
    <sym> \h+
	<type-name> \h+
    <name> <value-ret> \n
    <new-indent> {}
    <body($<new-indent>.Str)>
	{
        $*last-statement-type = "Void"
	}
}
token control:sym<While>        {
	:my %*scope-vars := SetHash.new;
	<sym> \h+ <statement> \n
    <new-indent>{}
    <body($<new-indent>.Str)>
	{
        $*last-statement-type = "Void"
	}
}
proto token declare             { * }
token declare:sym<var>          {
    <type-name> \h+
    <name>
    {
		self.error: "redeclaration of variable '$<name>'" if %*scope-vars{ $<name>.Str };
        %*vars{ $<name> } = $<type-name>.Str;
        %*scope-vars{ $<name>.Str }++;
        $*last-statement-type = $<type-name>.Str
    }
    [ \h+ <statement> ]?
}
token declare:sym<func>         { <decl-func(%*vars.clone, @*types.clone, %*functions)> }
proto token statement           { * }
token statement:sym<decl>       { <declare> }
token statement:sym<value>      { <value-ret> }
token statement:sym<set-var>    {
    "Set" \h+ <?>
    <name>
    {}
    \h+ <wanted(%*vars{ $<name> })>
}
token statement:sym<control>    { <control> }
token statement:sym<error>		{ <name> {} && <error("unrecognized function '$<name>'")> }
proto token value-ret           { * }
token value-ret:sym<val>        { <value> }
token value-ret:sym<call-fun>   {
    <func-name> [ \h+
		{}
		<arg-list(%*functions{$<func-name>}<signature>.clone)>
		{ $*last-statement-type = %*functions{$<func-name>}<return> }
	]?
}
token value-ret:sym<var>        {
    <var-name>
    {
        $*last-statement-type = %*vars{ $<var-name> }
    }
}
token decl-func(%*vars, @*types, %*functions)       {
	:my %*scope-vars := SetHash.new;
    :my $*last-statement-type;
    <func-proto> \n
    <new-indent>{}
    <body($<new-indent>.Str)>
    {
        self.error: "function $<func-proto><name> should return $<func-proto><type-name> but is returning $*last-statement-type"
            unless self.isa($<func-proto><type-name>.Str, "Void")
				or self.isa($*last-statement-type, $<func-proto><type-name>.Str)
    }
}
token new-indent                { <.indent> \h+ || <error("error on indentation")> }
token pair-args(@signature)     {
    <type-name> \h+
    <name> {
        @signature.push: $<type-name>.Str;
        %*vars{$<name>} = $<type-name>.Str;
        %*scope-vars{$<name>.Str}++
    }
}
token func-proto                {
    :my @signature;
    <func-keyword> \h+
    [
        || <type-name>
        || error("invalid type")
    ]
    \h+
    [
        || <name>
        || <error("invalid function name")>
    ]
    {
        self.error: "function {$<name>.Str} already defined" if %*functions{ $<name>.Str }:exists;
        %*functions{ $<name>.Str }<return> = $<type-name>.Str;
    }
    [
        \h+
        [
            || <pair-args(@signature)>* % \h+ { %*functions{ $<name>.Str }<signature> = @signature.clone}
            || <error("wrong arguments on function $<name>")>
        ]
    ]?
}
token func-keyword              { "Function" }
token body($*INDENT)            {
    <statement>
    [\n <line>+ % \n+]?
}
multi token arg-list(Any:U)            {
    <error("function wants no arguments")>
}
multi token arg-list(@sig)            {
    :my $elems = @sig.elems;
    [
        || <wanted(@sig.shift)> ** { $elems } % \h+
        || <error("function wants $elems arguments")>
    ]
}
token wanted($*wanted)          {
    || <value-ret>
    || <error("Argument not recognized")>
}
proto token value               { * }
token value:sym<num>            { <.want("Number")> \d+ { $*last-statement-type = "Number" } }
token value:sym<sstr>           { <.want("String")> "'" ~ "'" $<str>=<-[']>* { $*last-statement-type = "String" } }
token value:sym<dstr>           { <.want("String")> '"' ~ '"' <str>? { $*last-statement-type = "String" } }
token str                       { <str-part>* }
proto token str-part            { * }
token str-part:sym<str>         { <-[$"]>+ }
token str-part:sym<var>         {
    :my $*wanted = "String";
    '$' [ <var-name> || '{' ~ '}' <var-name> || <error("Variable wasn't declared")> ]
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
        self.error("wanted $*wanted but got variable of type %*vars{$<var>}")
            if $*wanted.defined and not self.isa(%*vars{$<var>}, $*wanted);
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
            if $*wanted.defined and not self.isa(%*functions{$<func>.Str}<return>, $*wanted);
    }
}

token want(Str $want) {
    || <?{ not $*wanted.defined or self.isa($want, $*wanted) }>
    || <error("wanted $*wanted but got $want")>
}
method error($msg) {
    my $parsed-so-far = self.target.substr(0, self.pos);
    my $break = self.pos + 15;
    with self.target.index("\n", self.pos) {
        $break min= $_ - self.pos
    }
    my $not-parsed = self.target.substr: self.pos, $break;
    my @lines = $parsed-so-far.lines;
    note "\nCompiling ERROR on line @lines.elems():\n";
    note "$msg: \o033[32m@lines[*-1].trim-leading()\o033[33m⏏\o033[31m$not-parsed\o033[m";
    exit 1;
}
method isa($t1, $t2) {
    # TODO: test its parents too
    $t1 eq $t2
}
