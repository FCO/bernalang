use Berna::AST;
unit class Berna::Compiler;

multi method compile(@ast) { |@ast.map: { |self.compile: $_ } }

multi method compile(Berna::AST::CallFunction $_) {
    |.args.reverse.map(-> $param {
        |self.compile($param)
    }),
    ["CALL-FUNC", .function-name, .args.elems]
}

multi method compile(Berna::AST::NVal $_) {
    (["PUSH-CONST", .value],)
}
