use Berna::AST;
unit class Berna::Compiler;

method take-inc(\val) {
    $*next++;
    take val
}

multi method compile(@ast) {
    gather {
        my $*next = 0;
        for @ast {
            my $*lines-before = 0;
            self.compile: $_
        }
    }
}

multi method compile(Berna::AST::CallFunction $_, :$prev is copy = 0) {
    $prev++;
    my $begin = $*next;
    my @lines = gather {
        my $*next = $begin;
        for .args.reverse -> $param {
            self.compile: $param, :prev($prev);
        }
        $prev += $*next - $begin
    }
    self.compile: Berna::AST::NVal.new: :value($*next + $prev + 1);
    self.take-inc: $_ for @lines;
    self.take-inc: ["CALL-FUNC", .function-number, .args.elems];
}

multi method compile(Berna::AST::NVal $_) {
    self.take-inc: ["PUSH-CONST", .value]
}

multi method compile(Berna::AST::SVal $_) {
    self.take-inc: ["PUSH-CONST", .value]
}

multi method compile(Berna::AST::DeclareVariable $_) {
    self.take-inc: ["DECLARE-VAR", .variable-number, .type];
    self.compile: .SetVariable
}

multi method compile(Berna::AST::DeclareFunction $_) {
    self.take-inc: ["DECLARE-FUNC", .variable-number, .type];
    self.compile: .SetFunction
}

multi method compile(Berna::AST::SetVariable $_) {
    self.compile(.rvalue),
    self.take-inc: ["SET-VAR", .variable-number]
}

multi method compile(Berna::AST::SetFunction $_) {
    self.compile(.rvalue),
    self.take-inc: ["SET-FUNC", .variable-number]
}

multi method compile(Berna::AST::PullToVariable $_) {
    self.take-inc: ["SET-VAR", .variable-number]
}

multi method compile(Berna::AST::VariableVal $_) {
    self.take-inc: ["GET-VAR", .variable-number]
}

multi method compile(Berna::AST::Param $_) {
    self.compile: Berna::AST::DeclareVariable.new:
        :variable-name(.name),
        :variable-number(.number),
        :type(.type)
    ;
    self.compile: Berna::AST::PullToVariable.new:
        :variable-name(.name),
        :variable-number(.number),
        :type(.type)
}

multi method compile(Berna::AST::If $_) {
    self.compile: .condition;
    my $begin = $*next;
    my @body = gather {
        my $*next = $begin + 3;
        self.compile: $_ for .body
    }
    self.compile: Berna::AST::NVal.new: :value($*next + @body + 4);
    self.take-inc: ["JUMP-IF-FALSE"];
    self.take-inc: ["NEW-SCOPE"];
    self.take-inc: $_ for @body;
    self.take-inc: ["POP-SCOPE"];
}

multi method compile(Berna::AST::Function $_) {
    my $type            = .type;
    my $variable-name   = .name;
    my $variable-number = .number;
    my $rvalue          = Berna::AST::NVal.new: :value($*next + 4);
    self.compile: Berna::AST::DeclareFunction.new:
        :$type,
        :$variable-name,
        :$variable-number,
        :$rvalue
    ;
    my $begin           = $*next;
    my @lines = gather {
        my $*next = $begin + 1;
        self.compile: $_ for .signature;
        self.compile: $_ for .body
    }
    self.take-inc: ["GOTO", @lines + $begin + 2];
    self.take-inc: $_ for @lines;
    self.take-inc: ["RETURN"]
}
