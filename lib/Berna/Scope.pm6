unit class Berna::Scope;

class Declared {}

has             %.vars;
has ::?CLASS    $.parent;

method declare($name) { %!vars{$name} = Declared }
method store($name, $value) { die unless %!vars{$name}:exists; %!vars{$name} = $value }
multi method lookup($name) { self.lookup($name, :local) // $!parent.?lookup($name) }
multi method lookup($name, Bool :$local where * === True) { %!vars{ $name } }
