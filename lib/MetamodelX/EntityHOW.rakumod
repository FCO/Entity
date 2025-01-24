unit class MetamodelX::EntityHOW is Metamodel::ClassHOW;
use JSON::Class;

has Mu $.interface;
has Mu %.commands{Str};
has Mu %.events{Str};
has    @!ids;

role Command {}
role Event {}

method ids($entity) {
	@( @!ids.map: { .get-value: $entity } )
}

multi method interface($entity) {
	$!interface
}

method exports($entity --> Map()) {
	$entity.^name => $entity,
	|%!commands, |%.events
}

method compose(Mu $entity) {
	class Query {
		has &.return
	}
	for $entity.^attributes.grep: *.?is-entity-id -> $id {
		@!ids.push: $id;
		$!interface.^add_attribute: $id.clone: :package($!interface), :required;
	}
	$entity.^add_method: "!handle", my method ($event) {
		my $ret = self."!run"($event);
		$ret ~~ self.WHAT ?? $ret !! self
	}
	$entity.^add_multi_method: "!run", my method (Query $event) {
		$event.return.(self)
	}
	$!interface.^add_multi_method: "!run", my method ($obj) {die "unrecognized object $obj.raku()"}
	$!interface.^add_method: "query", my method {
		my Promise $prom .= new;
		my \obj = Query.new: :return(-> $val { $prom.keep: $val });
		.(obj) with &*EMIT;
		await $prom
	}
	$!interface.^compose;
	callsame;
	for %!events.values -> $ev {
		for @!ids -> $id {
			$ev.^add_attribute:
				Attribute.new(
					:name($id.name),
					:type($id.type),
					:1ro,
					:package($ev),
					:1required,
					:1has_accessor,
				) does role EntityId { method is-entity-id { True } };
		}
		$ev.^add_role: JSON::Class;
		$ev.^compose
	}
	for %!commands.values -> $cmd {
		my @ids = do for @!ids -> $id {
			$cmd.^add_attribute:
				my $attr = Attribute.new(
					:name($id.name),
					:type($id.type),
					:1ro,
					:package($cmd),
					:1required,
					:1has_accessor,
				) does role EntityId { method is-entity-id { True } };
				$attr
		}
		$cmd.HOW does role EntityId { method entity-ids($cmd) { |@ids.map: { .get_value: $cmd } } }
		$cmd.^add_role: JSON::Class;
		$cmd.^compose
	}
}

proto method add_method(Mu $target, Str $name, &code, :$handles) { * }

multi method add_method(Mu $target, Str $name, &code where { .?is-command }, :$handles) {
	my $cmd-name = "Command{ $name.tc.subst: /\W(\w)/, { $0.uc }, :g }";
	%!commands{$cmd-name} = my $cmd = Metamodel::ClassHOW.new_type: :name($cmd-name);
	$cmd.^add_role: Command;
	for &code.signature.params.grep(*.named).head: *-1 -> $param {
		my $attr-name = $param.name.subst: /^(<[$@%&]>)(\w+)$/, { "$0!$1" };
		my $attr = Attribute.new:
			:name($attr-name),
			:1ro,
			:1has_accessor,
			:type($param.type),
			:package($cmd),
		;
		$cmd.^add_attribute: $attr;
	}
	$!interface = Metamodel::ClassHOW.new.new_type: :name($target.^name)
		unless $!interface.HOW.?name($!interface) eq $target.^name;
	my %defaults = &code.signature.params.map: -> $attr {
		my $dv-attr = $attr.^attributes.first: *.name eq '$!default_value';
		my $dv = $dv-attr.get_value: $attr;
		next without $dv;
		$attr.name.substr(1) => $dv ~~ Callable ?? $dv.() !! $dv
	}
	my &m = method (Any:D: |c) {
		CATCH {
			default {
				.note
			}
		}
		my %ids := self.^attributes.grep(*.?is-entity-id).map({ .name.substr(2) => .get_value(self) }).Map;
		my \obj = $cmd.new: |%ids, |%defaults, |c;
		.(obj) with &*EMIT;
		obj
	}
	$target.^add_method: "$name", &m;
	$!interface.^add_method: "$name", &m;
	$target.^add_multi_method: "!run", my method (Command $command where {$_ ~~ $cmd}) {
		CATCH {
			default {
				.note
			}
		}
		my %*entity-ids := $command.^attributes.grep(*.?is-entity-id).map({ .name.substr(2) => .get_value($command) }).Map;
		return code $target, |$cmd.^attributes.map(-> $attr {
			$attr.name.substr(2) => $attr.get_value: $command
		}).Map;
	}
}

multi method add_method(Mu $target, Str $name, &code where { .?is-event }, :$handles) {
	my $ev-name = "Event{ $name.tc.subst: /\W(\w)/, { $0.uc }, :g }";
	%!events{$ev-name} = my $ev = Metamodel::ClassHOW.new_type: :name($ev-name);
	$ev.^add_role: Event;
	for &code.signature.params.grep(*.named).head: *-1 -> $param {
		my $attr-name = $param.name.subst: /^(<[$@%&]>)(\w+)$/, { "$0!$1" };
		my $attr = Attribute.new:
			:name($attr-name),
			:1ro,
			:1has_accessor,
			:type($param.type),
			:package($ev),
		;
		$ev.^add_attribute: $attr;
	}
	my %defaults = &code.signature.params.map: -> $attr {
		my $dv-attr = $attr.^attributes.first: *.name eq '$!default_value';
		my $dv = $dv-attr.get_value: $attr;
		next without $dv;
		$attr.name.substr(1) => $dv ~~ Callable ?? $dv.() !! $dv
	}
	$target.^add_method: $name, my method (|c) {
		CATCH {
			default {
				.note
			}
		}
		my %ids = %*entity-ids if %*entity-ids;
		my \obj = $ev.new: |%ids, |%defaults, |c;
		.(obj) with &*EMIT;
		obj
	}
	$target.^add_multi_method: "!run", my method (Any:U: Event $event where {$_ ~~ $ev}) {
		CATCH {
			default {
				.note
			}
		}
		code self, |$ev.^attributes.map(-> $attr {
			$attr.name.substr(2) => $attr.get_value: $event
		}).Map;
	}

	$target.^add_multi_method: "!run", my method (Any:D: Event $event where {$_ ~~ $ev}) {
		CATCH {
			default {
				.note
			}
		}
		code self, |$ev.^attributes.map(-> $attr {
			$attr.name.substr(2) => $attr.get_value: $event
		}).Map;
	}
}

multi method add_method(|) {
	nextsame
}
