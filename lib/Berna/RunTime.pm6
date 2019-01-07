use Berna::Scope;
unit class Berna::RunTime;

has                 @.code is required;
has Bool            $.debug     = False;
has UInt            $!position  = 0;
has Berna::Scope    $.global   .= new;
has Berna::Scope    $!scope     = $!global;

has @!stack handles <push pop>;

method run {
    while $!position < @!code.elems {
        self.eval: |@!code[$!position]
    }
}

proto method eval(|c) {
    note "CMD:   ", c.Array if $!debug;
    {*};
    note "STACK: ", @!stack if $!debug;
    $!position++;
    note "POSITION: $!position" if $!debug;
}

multi method eval("GOTO", $num) { $!position = $num - 1 }

multi method eval("PUSH-CONST", $val) { self.push: $val }

multi method eval("CALL-FUNC", "toString", 1) { my $ret = ~self.pop; self.pop; self.push: $ret }

multi method eval("CALL-FUNC", "concat", 2) { my $ret = self.pop ~ self.pop; self.pop; self.push: $ret }

multi method eval("CALL-FUNC", "print", 1) { say self.pop; self.pop }

multi method eval("DECLARE-VAR", Str $name, Str $type) { $!scope.declare: $name, $type }

multi method eval("SET-VAR", Str $name) { $!scope.store: $name, self.pop }

multi method eval("GET-VAR", Str $name) { self.push: $!scope.lookup: $name }

multi method eval("CALL-FUNC", $name, $num) { $!position = -1 + $!scope.lookup: $name }

multi method eval("RETURN") { # TODO: get response
    my $ret #`( = self.pop);
    $!position = self.pop - 1;
    #self.push: $ret
}
