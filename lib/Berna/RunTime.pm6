use Berna::Scope;
unit class Berna::RunTime;

has                 @.code is required;
has UInt            $!position = 0;
has Berna::Scope    $.global   .= new;
has Berna::Scope    $!scope     = $!global;

has @!stack handles <push pop>;

method run {
    while $!position < @!code.elems {
        self.eval: |@!code[$!position]
    }
}

proto method eval(|) { {*}; $!position++ }

multi method eval("PUSH-CONST", $val) { self.push: $val }

multi method eval("CALL-FUNC", "toString", 1) { self.push: ~self.pop }

multi method eval("CALL-FUNC", "concat", 2) { self.push: self.pop ~ self.pop }

multi method eval("CALL-FUNC", "print", 1) { say self.pop }

multi method eval("DECLARE-VAR", Str $name) { $!scope.declare: $name }

multi method eval("SET-VAR", Str $name) { $!scope.store: $name, self.pop }

multi method eval("GET-VAR", Str $name) { self.push: $!scope.lookup: $name }
