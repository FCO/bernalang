use Berna::Parser;
use Berna::Compiler;
use Berna::RunTime;
subset Code of Str;

my %*SUB-MAIN-OPTS = :named-anywhere;

my $parser   = Berna::Parser.new;
my $compiler = Berna::Compiler.new;

multi MAIN(Code :$e!) {
    say $parser.parse: $e
}

multi MAIN(*@file, Bool :$print-code = False, Bool :$print-ast = False, Bool :$print-list = False) {
    my $code = @file>>.IO>>.slurp.join("\n");
    if $print-code {
        note "CODE:";
        note $code;
        note "------------\n"
    }
    my $ast = $parser.parse: $code;
    if $print-ast {
        note "AST:";
        note $ast>>.gist.join: "\n";
        note "------------\n"
    }
    my @list = $compiler.compile: $ast;
    if $print-list {
        note "LIST:";
        .note for @list;
        note "------------\n"
    }

    my $run-time = Berna::RunTime.new: :code(@list);
    $run-time.run
}
