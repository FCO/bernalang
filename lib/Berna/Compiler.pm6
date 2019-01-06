use Berna::AST;
unit class Berna::Compiler;

multi method compile(@ast) { |@ast.map: { |self.compile: $_ } }

multi method compile(Berna::AST::CallFunction $_) {
    (
        |.args.reverse.map(-> $param {
            |self.compile($param)
        }),
        ["CALL-FUNC", .function-name, .args.elems]
    )
}

multi method compile(Berna::AST::NVal $_) {
    (["PUSH-CONST", .value],)
}

multi method compile(Berna::AST::DeclareVariable $_) {
    (["DECLARE-VAR", .variable-name], |self.compile: .SetVariable)
}

multi method compile(Berna::AST::SetVariable $_) {
    |self.compile(.rvalue),
    ["SET-VAR", .variable-name]
}

multi method compile(Berna::AST::VariableVal $_) {
    (["GET-VAR", .variable-name],)
}
