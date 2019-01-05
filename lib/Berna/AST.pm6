role Berna::AST {
    method args { ... }
    method type { ... }

}

role Berna::AST::Gistable {
    method gist {
        "{self.^name}:\n{$.args.map(*.gist.indent: 3).join: "\n"}"
    }
}

role Berna::AST::HasType does Berna::AST {
    method type { ... }
}

role Berna::AST::Value does Berna::AST::HasType {
    has $.value is required;

    method args {}
    method gist {
        "{self.^name} :value($!value)"
    }
}

class Berna::AST::SVal does Berna::AST::Value {
    method type { "String" }
}

class Berna::AST::NVal does Berna::AST::Value {
    method type { "Number" }
}

class Berna::AST::BVal does Berna::AST::Value {
    method type { "Boolean" }
}

role Berna::AST::Variable does Berna::AST {
    has Str $.variable-name is required;
    has Str $.type is required;
    method gist {
        "{self.^name} :variable-name($!variable-name)"
    }
}

class Berna::AST::VariableVal does Berna::AST::HasType does Berna::AST::Variable {
    method args {}
}

class Berna::AST::CallFunction does Berna::AST::HasType {
    has Str         $.function-name is required;
    has Str         $.type is required;
    has Berna::AST  @.args handles <push pop>;

    method gist {
        "{self.^name} :function-name($!function-name):\n{$.args.map(*.gist.indent: 3).join: "\n"}"
    }
}

class Berna::AST::Param does Berna::AST::HasType {
    has Str $.name is required;
    has Str $.type is required;
    method args {}
}

class Berna::AST::Function does Berna::AST::HasType {
    has Str                 $.name;
    has Str                 $.type is required;
    has Berna::AST::Param   @.signature;
    has Berna::AST          @.body handles <push pop>;

    method args { |@!body }
    method gist {
        "{self.^name} :name($!name):\n{[
            ":signature[\n{@.signature.map(*.gist).join("\n").indent: 3}\n]",
            ":body[\n{@.body.map(*.gist).join("\n").indent: 3}\n]"
        ].join("\n").indent: 3}"
    }
}
