use Berna::AST;
unit class Berna::Compiler;

has UInt $!next = 0;

method take-inc(\val) {
    $!next++ unless $*do-not-incr;
    take val
}

multi method compile(@ast) {
    gather for @ast {
        self.compile: $_
    }
}

multi method compile(Berna::AST::CallFunction $_) {
    my @lines = |gather {
        my $*do-not-incr = True;
        for .args.reverse -> $param {
            self.compile: $param;
        }
        self.take-inc: ["CALL-FUNC", .function-name, .args.elems]
    }
    self.compile: Berna::AST::NVal.new: :value($!next + @lines + 1);
    self.take-inc: $_ for @lines
}

multi method compile(Berna::AST::NVal $_) {
    self.take-inc: ["PUSH-CONST", .value]
}

multi method compile(Berna::AST::SVal $_) {
    self.take-inc: ["PUSH-CONST", .value]
}

multi method compile(Berna::AST::DeclareVariable $_) {
    self.take-inc: ["DECLARE-VAR", .variable-name, .type];
    self.compile: .SetVariable
}

multi method compile(Berna::AST::SetVariable $_) {
    self.compile(.rvalue),
    self.take-inc: ["SET-VAR", .variable-name]
}

multi method compile(Berna::AST::PullToVariable $_) {
    self.take-inc: ["SET-VAR", .variable-name]
}

multi method compile(Berna::AST::VariableVal $_) {
    self.take-inc: ["GET-VAR", .variable-name]
}

multi method compile(Berna::AST::Param $_) {
    self.compile: Berna::AST::DeclareVariable.new: :variable-name(.name), :type(.type);
    self.compile: Berna::AST::PullToVariable.new:  :variable-name(.name), :type(.type)
}

multi method compile(Berna::AST::Function $_) {
    my $type            = "Function";
    my $variable-name   = .name;
    my $rvalue          = Berna::AST::NVal.new: :value($!next + 4);
    self.compile: Berna::AST::DeclareVariable.new: :$type, :$variable-name, :$rvalue;
    my $begin           = $!next;
    my @lines = |gather {
        my $*do-not-incr = True;
        self.compile: $_ for .signature;
        self.compile: $_ for .body
    }
    self.take-inc: ["GOTO", @lines + $begin + 2];
    self.take-inc: $_ for @lines;
    self.take-inc: ["RETURN"]
}
