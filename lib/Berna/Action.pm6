use Berna::AST;
unit class Berna::Action;
method TOP($/) { make $<line>>>.made }
method line($/) { make $<statement>.made }
method unexpected-data($/) {}
method indent($/) {}
method control:sym<If>($/) {}
method control:sym<For>($/) {}
method control:sym<While>($/) {}
method declare:sym<var>($/) {
    make Berna::AST::DeclareVariable.new:
        :type($<type-name>.made),
        :variable-name($<name>.made),
        |(:rvalue(.made) with $<statement>)
}
method declare:sym<func>($/) { make $<decl-func>.made }
method statement:sym<decl>($/) { make $<declare>.made }
method statement:sym<value>($/) { make $<value-ret>.made }
method value-ret:sym<val>($/) { make $<value>.made }
method value-ret:sym<call-fun>($/) {
    make Berna::AST::CallFunction.new:
    :type(%*functions{$<func-name>}<return>),
    :function-name($<func-name>.made),
    |(:args($_) with $<arg-list>.made)
}
method value-ret:sym<var>($/) { make Berna::AST::VariableVal.new: :variable-name($<var-name>.Str), :type(%*vars{$<var-name>.Str}) }
method decl-func($/) {
    my $func = $<func-proto>.made;
    $func.push: $_ for $<body>.made;
    make $func
}
method new-indent($/) {}
method pair-args($/) { make Berna::AST::Param.new: :type($<type-name>.made), :name($<name>.made) }
method func-proto($/) {
    make Berna::AST::Function.new:
        :type($<type-name>.made),
        :name($<name>.made),
        :signature($<pair-args>>>.made),
}
method func-keyword($/) {}
method body($/) {
    make [
        $<statement>.made,
        |$<line>>>.made
    ]
}
method arg-list($/) { make $<wanted>>>.made }
method wanted($/) { make $<value-ret>.made }
method value:sym<num>($/) { make Berna::AST::NVal.new: :value($/.Int) }
method value:sym<sstr>($/) { make Berna::AST::SVal.new: :value($<str>.Str) }
method value:sym<dstr>($/) { make $<str>.made }
method str($/) {
    if $<str-part> == 1 {
        make $<str-part>.head.made
    } else {
        make Berna::AST::CallFunction.new:
            :function-name<concat>,
            :args(|$<str-part>>>.made),
            :type<String>
    }
}
method str-part:sym<str>($/) { make Berna::AST::SVal.new: :value($/.Str) }
method str-part:sym<var>($/) { make Berna::AST::VariableVal.new: :variable-name($<var-name>.Str), :type(%*vars{$<var-name>.Str}) }
method name($/) { make $/.Str }
method type-name($/) { make $/.Str }
method var($/) { $/.Str }
method var-name($/) { make $<var>.made }
method func($/) { make $/.Str }
method func-name($/) { make $<func>.made }
method want($/) {}
