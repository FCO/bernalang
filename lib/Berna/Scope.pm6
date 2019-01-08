unit class Berna::Scope;

has             @.vars;
has ::?CLASS    $.parent;
has             $.id;

method TWEAK(|) { $!id = $++ }

method child {
    self.new: :parent(self)
}

method gist {
    "[$!id|{@!vars.kv.map(-> $k, \v { "$k => { $_ ~~ Hash ?? .<line> !! $_ with v<value> }" with v }).join: ", "}|{with $!parent { .id } else { "NULL"}}]"
}

method declare(::?CLASS:D: UInt $name, Str $type) {
    die "Try to redeclare var called $name" if @!vars[$name].defined;
    @!vars[$name] = {:$type}
}
multi method store(::?CLASS:D: UInt $name, $value) {
    with self.lookup: $name, 0, 1 {
        .<value> = $value
    } else {
        die "Try to store on a undefined var called $name"
    }
}
multi method lookup(::?CLASS:D: UInt $name) { self.lookup: $name, 0, 0 }
multi method lookup(::?CLASS:D: UInt $name, 0, 0) {
    self.lookup($name, 0, 1)<value>
}
multi method lookup(::?CLASS:D: UInt $name, 0, 1) {
    do with @!vars[ $name ] {
        $_
    } else {
        do with $!parent {
            .lookup($name, 0, 1)
        } else {
            die "Variable '$name' not found"
        }
    }
}
multi method lookup(::?CLASS:D: UInt $name, 1, 0) {
    callwith($name, 1, 1)<value>
}
multi method lookup(::?CLASS:D: UInt $name, 1, 1) {
    @!vars[ $name ]
}
multi method typeof(::?CLASS:D: UInt $name) {
    self.lookup($name, 0, 1)<type>
}
