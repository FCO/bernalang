unit class Berna::Scope;

has             %.vars;
has ::?CLASS    $.parent;
has             $.id;

method TWEAK(|) { $!id = $++ }

method child {
    ::?CLASS.new: :parent(self)
}

method gist {
    "[$!id|{%!vars.kv.map(-> $k, %v { "$k => { $_ ~~ Hash ?? .<line> !! $_ with %v<value> }" }).join: ", "}|{with $!parent { .id } else { "NULL"}}]"
}

method declare(::?CLASS:D: Str $name, Str $type) {
    die "Try to redeclare var called $name" if %!vars{$name}:exists;
    %!vars{$name} = {:$type}
}
multi method store(::?CLASS:U: |) {die "scope undefined"}
multi method store(::?CLASS:D: Str $name, $value) {
    with self.lookup: $name, :struct {
        .<value> = $value
    } else {
        die "Try to store on a undefined var called $name"
    }
}
multi method lookup(::?CLASS:D: Str $name) {
    self.lookup($name, :struct)<value>
}
multi method lookup(::?CLASS:D: Str $name, Bool :$struct! where * === True) {
    do with %!vars{ $name } {
        $_
    } else {
        do with $!parent {
            .lookup($name, :struct)
        } else {
            die "Variable '$name' not found"
        }
    }
}
multi method lookup(::?CLASS:D: Str $name, Bool :$local! where * === True) {
    callwith($name, :local, :struct)<value>
}
multi method lookup(::?CLASS:D: Str $name, Bool :$local! where * === True, Bool :$struct! where * === True) is rw {
    %!vars{ $name }
}
multi method typeof(::?CLASS:D: Str $name) {
    self.?typeof($name, :local) // $!parent.?typeof($name)
}
multi method typeof(::?CLASS:D: Str $name, Bool :$local where * === True) {
    %!vars{ $name }<type>
}
