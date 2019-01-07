unit class Berna::Scope;

has             %.vars;
has ::?CLASS    $.parent;

method child {
    ::?CLASS.new: :parent(self)
}

method declare(::?CLASS:D: $name, $type) {
    die "Try to redeclare var called $name" if %!vars{$name}:exists;
    %!vars{$name} = {:$type}
}
method store(::?CLASS:D: $name, $value) {
    die "Try to store on a undefined var called $name" unless %!vars{$name}:exists;
    %!vars{$name}<value> = $value
}
multi method lookup(::?CLASS:D: $name) {
    self.?lookup($name, :local) // $!parent.?lookup($name)
}
multi method lookup(::?CLASS:D: $name, Bool :$local where * === True) {
    %!vars{ $name }<value>
}
multi method typeof(::?CLASS:D: $name) {
    self.?typeof($name, :local) // $!parent.?typeof($name)
}
multi method typeof(::?CLASS:D: $name, Bool :$local where * === True) {
    %!vars{ $name }<type>
}
