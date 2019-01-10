use Berna::Scope;
use GccJit;
unit class Berna::MachineCode;

has GccJit              $!context           .= new;
has GccJit::Type        $!stack-item-type    = $!context.int;
#has GccJit::Type        $!stack-item-type    = $!context.new-union-type:
#    "stack_item",
#    $!context.new-field($!context.int, "int"),
#    $!context.new-field($!context.const-char-ptr, "str"),
#;
has GccJit::Type        $!stack-type         = $!stack-item-type.array;
has GccJit::Function    $!main               = $!context.new-exported-function: .int, "main";
has GccJit::Block       $!init               = $!main.new-block: "initial";
has GccJit::LValue      $!stack              = $!main.new-local: $!stack-type, "stack";
has GccJit::LValue      $!stack-depth        = $!main.new-local: $!context.int, "stack_depth";
has GccJit::LValue      $!tmp1               = $!main.new-local: $!context.int, "tmp1";
has GccJit::LValue      $!tmp2               = $!main.new-local: $!context.int, "tmp2";
has                     @.code is required;
has                     %.vars is required;
has GccJit::Block       @!blocks             = (^@!code).map: { $!main.new-block: "op_$_" };
has Bool                $.debug              = False;
has UInt                $!position           = 0;
has Berna::Scope        $.global            .= new;
has Berna::Scope        @!scope handles (scope => "tail")    = $!global;
has Str                 @!type;

method add-print(GccJit::RValue $rvalue) {
    state $printf //= $!context.new-imported-function:
        .int, "printf",
        $!context.new-param($!context.const-char-ptr, "format"),
        $!context.new-param($!context.int, "num"),
    ;
    @!blocks[$!position].add-eval: $!context.new-call: $printf, $!context.new-string-literal: "%d\n", $rvalue
}

method add-push(GccJit::RValue $rvalue, GccJit::Location :$location) {
    @!blocks[$!position].add-assignment: $!context.new-array-access($!stack, $!stack-depth), $rvalue, :$location;
    @!blocks[$!position].add-assignment-op: $!stack-depth, PLUS, $!context.new-rvalue-from-int(1), :$location;
}

method add-pop(GccJit::LValue $lvalue, GccJit::Location :$location) {
    @!blocks[$!position].add-assignment-op: $!stack-depth, MINUS, $!context.new-rvalue-from-int(1), :$location;
    @!blocks[$!position].add-assignment: $lvalue, :$location, $!context.new-array-access: $!stack, $!stack-depth;
}

method run {
    for @!code.keys -> $!position {
        self.eval: |@!code[$!position]
    }
    $!context.compile-to-executable;
}

multi method eval("GOTO", UInt:D $num) {
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

multi method eval("JUMP-IF-FALSE", UInt:D $num) {
    self.add-pop: $!tmp1;
    @!blocks[$!position].end-with-conditional: $!tmp2, @!blocks[$!position + 1], @!blocks[ $num ]
}

multi method eval("PUSH-CONST", Int $val) { self.add-push: $!context.new-rvalue-from-int: $val }

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<print> }, 1, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-print: $!tmp1;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toString> }, 1, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-push: $!tmp1;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

#multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toBoolean> }, 1) {
#    my $ret = ?self.pop;
#    $!position = self.pop - 1;
#    self.push: $ret
#}
#
#multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<toNumber> }, 1) {
#    my $ret = +self.pop;
#    $!position = self.pop - 1;
#    self.push: $ret
#}
#
#multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<concat> }, 2) {
#    my $ret = self.pop ~ self.pop;
#    $!position = self.pop - 1;
#    self.push: $ret
#}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<sum> }, 2, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-pop: $!tmp2;
    self.add-push: $!context.new-binary-plus: .int, $!tmp1, $!tmp2;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<sub> }, 2, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-pop: $!tmp2;
    self.add-push: $!context.new-binary-minus: .int, $!tmp1, $!tmp2;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<mul> }, 2, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-pop: $!tmp2;
    self.add-push: $!context.new-binary-mult: .int, $!tmp1, $!tmp2;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<div> }, 2, UInt:D $num) {
    self.add-pop: $!tmp1;
    self.add-pop: $!tmp2;
    self.add-push: $!context.new-binary-divide: .int, $!tmp1, $!tmp2;
    @!blocks[$!position].end-with-jump: @!blocks[ $num ]
}

#multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<equal> }, 2) {
#    my $ret = self.pop == self.pop;
#    $!position = self.pop - 1;
#    self.push: $ret
#}
#
#multi method eval("CALL-FUNC", UInt $ where { $_ == %!vars<not> }, 1) {
#    my $ret = not self.pop;
#    $!position = self.pop - 1;
#    self.push: $ret
#}

#multi method eval("DECLARE-VAR", UInt $name, Str $type) { self.scope.declare: $name, $type }
#
#multi method eval("DECLARE-FUNC", UInt $name, Str $type) { self.scope.declare: $name, $type }
#
#multi method eval("NEW-SCOPE") { @!scope.push: self.scope.child }
#
#multi method eval("POP-SCOPE") { @!scope.pop }
#
#multi method eval("SET-VAR", UInt $name) { self.scope.store: $name, self.pop }
#
#multi method eval("SET-FUNC", UInt $name) { self.scope.store: $name, %( line => self.pop, scope => self.scope ) }
#
#multi method eval("GET-VAR", UInt $name) { self.push: self.scope.lookup: $name }
#
#multi method eval("CALL-FUNC", $name, $num) {
#    my $func-data = self.scope.lookup: $name;
#    @!scope.push: $func-data<scope>.child;
#    @!type.push: self.scope.typeof: $name;
#    $!position = $func-data<line> - 1;
#}
#
#multi method eval("RETURN") {
#    @!scope.pop;
#    my $type = @!type.pop;
#    my $ret = self.pop unless $type eq "Void";
#    $!position = self.pop - 1;
#    self.push: $ret unless $type eq "Void"
#}
