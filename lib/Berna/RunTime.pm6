use Berna::Scope;
unit class Berna::RunTime;

has                 %.vars is required;
has                 @.code is required;
has Bool            $.debug     = False;
has UInt            $!position  = 0;
has Berna::Scope    $.global   .= new;
has Berna::Scope    @!scope handles (scope => "tail")    = $!global;
has Str             @!type;

has @!stack handles <push pop>;

method run {
    while $!position < @!code.elems {
        self.eval: |@!code[$!position]
    }
    exit $_ with self.pop
}

proto method eval(|c) {
    note "CMD:     ", c.Array if $!debug;
    {*};
    note "STACK:   ", @!stack if $!debug;
    note "SCOPE:   ", @!scope if $!debug;
    $!position++;
    note "POSITION: $!position" if $!debug;
}

multi method eval("GOTO", $num) { $!position = $num - 1 }

multi method eval("JUMP-IF-FALSE") { my $line = self.pop; if !self.pop { $!position = $line - 1 } }

multi method eval("PUSH-CONST", $val) { self.push: $val }

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<print> }, 1) {
    say self.pop;
    $!position = self.pop - 1
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toString> }, 1) {
    my $ret = ~self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toBoolean> }, 1) {
    my $ret = ?self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toNumber> }, 1) {
    my $ret = +self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<concat> }, 2) {
    my $ret = self.pop ~ self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<sum> }, 2) {
    my $ret = self.pop + self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<sub> }, 2) {
    my $ret = self.pop - self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<mul> }, 2) {
    my $ret = self.pop * self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<div> }, 2) {
    my $ret = self.pop / self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<equal> }, 2) {
    my $ret = self.pop == self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<not> }, 1) {
    my $ret = not self.pop;
    $!position = self.pop - 1;
    self.push: $ret
}

multi method eval("DECLARE-VAR", UInt $name, Str $type) { self.scope.declare: $name, $type }

multi method eval("DECLARE-FUNC", UInt $name, Str $type) { self.scope.declare: $name, $type }

multi method eval("NEW-SCOPE") { @!scope.push: self.scope.child }

multi method eval("POP-SCOPE") { @!scope.pop }

multi method eval("SET-VAR", UInt $name) { self.scope.store: $name, self.pop }

multi method eval("SET-FUNC", UInt $name) { self.scope.store: $name, %( line => self.pop, scope => self.scope ) }

multi method eval("GET-VAR", UInt $name) { self.push: self.scope.lookup: $name }

multi method eval("CALL-FUNC", $name, $num) {
    my $func-data = self.scope.lookup: $name;
    @!scope.push: $func-data<scope>.child;
    @!type.push: self.scope.typeof: $name;
    $!position = $func-data<line> - 1;
}

multi method eval("RETURN") {
    @!scope.pop;
    my $type = @!type.pop;
    my $ret = self.pop unless $type eq "Void";
    $!position = self.pop - 1;
    self.push: $ret unless $type eq "Void"
}
