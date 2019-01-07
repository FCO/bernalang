use Berna::Parser;
use Berna::Compiler;
use Berna::RunTime;
subset Code of Str;

my %*SUB-MAIN-OPTS = :named-anywhere;

my $parser   = Berna::Parser.new;
my $compiler = Berna::Compiler.new;

multi MAIN(*@file, *%_) {
    my $code = @file>>.IO>>.slurp.join("\n");
    run $code, |%_
}

multi MAIN(Str :$e!, *%_) {
    run $e, |%_
}

multi run(Str $code, Bool :$print-code = False, Bool :$print-ast = False, Bool :$print-list = False, Bool :$print-runtime = False) {
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
    die "unknown error" without $ast;
    my @list = $compiler.compile: $ast;
    if $print-list {
        note "LIST:";
        note $++, ": \t", $_ for @list;
        note "------------\n"
    }

    my $run-time = Berna::RunTime.new: :code(@list), :debug($print-runtime);
    $run-time.run
}
