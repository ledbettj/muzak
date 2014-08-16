require 'parslet'
require 'muzak/validation_error'
require 'muzak/note'
require 'muzak/chord'
require 'muzak/exec'
require 'muzak/command'
require 'muzak/assignment'
require 'muzak/dereference'
require 'muzak/filter'

module Muzak
  class Parser < Parslet::Parser
    rule(:terminator) { str("\n") | str(";") }
    rule(:space)      { match("[ \t\r]").repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:identifier) { match('[A-Za-z]') >> match('[A-Za-z0-9_]').repeat(0) }
    rule(:number)     { match('[0-9]').repeat(1) }
    rule(:decimal)    { _decimal | number }
    rule(:_decimal)   { number >> str('.') >> number }
    rule(:sign)       { str('-') | str('+') }
    rule(:signed_number) { sign.maybe >> number }
    rule(:signed_decimal) { sign.maybe >> decimal }

    root(:program)

    rule(:program) { terminated_statement.repeat(0) }
    rule(:terminated_statement) { statement >> space? >> terminator >> space? }

    rule(:statement) { assignment.as(:assign) | execution.as(:exec) | command.as(:cmd) | filter_block.as(:filter) }

    rule(:command) { octave_up | octave_set | octave_down | bpm_set }
    rule(:octave_up)   { str('^^').as(:octave_up) }
    rule(:octave_down) { str('vv').as(:octave_down) }
    rule(:octave_set)  { str('@') >> number.as(:octave) }
    rule(:bpm_set)     { str('%') >> number.as(:bpm) }

    rule(:assignment) { str('let') >> space >> identifier.as(:name) >> space? >> str('=') >> space? >> expression.as(:value) }

    rule(:expression) { sound | sound_list }

    rule(:sound_list) { str('[') >> space? >> sound.repeat(1) >> str(']') >> space? >> repeater.maybe }
    rule(:sound)      { note_or_chord >> repeater.maybe }
    rule(:note_or_chord) { note.as(:note) | chord.as(:chord) | dereference.as(:call) }
    rule(:repeater) { str('x') >> space? >> number.as(:count) >> space? }

    rule(:note) { note_name.as(:name) >> octave.maybe >> timing.maybe >> space? }

    rule(:note_name) { match('[A-G_]') >> match('[#b]').maybe }
    rule(:octave)    { str('^') >> signed_number.as(:octave) }
    rule(:timing)    { str(',') >> number.as(:timing) }

    rule(:chord)     { str('<') >> space? >> note.repeat(1).as(:notes) >> str('>') >> octave.maybe >> timing.maybe >> space? }

    rule(:execution) { expression }

    rule(:dereference) { str('(') >> space? >> identifier.as(:name) >> space? >> str(')') >> octave.maybe >> timing.maybe >> space? }


    rule(:filter_block) { str('|') >> space? >> identifier.as(:name) >> space? >> filter_args.maybe.as(:args) >> space? >> str('{') >> space? >> terminated_statement.repeat(0).as(:statements) >> str('}') }

    rule(:filter_args) { str('(') >> space? >> arg_list >> space? >> str(')') }
    rule(:arg) { identifier.as(:name) >> space? >> str('=') >> space? >> signed_decimal.as(:value) >> space? }
    rule(:arg_with_comma) { arg >> str(',') >> space? }
    rule(:arg_list) { arg_with_comma.as(:arg).repeat(0) >> arg.as(:arg) }

    class Transform < Parslet::Transform
      rule(note: subtree(:x), count: simple(:d)) { Note.new(x, count: d.to_i) }
      rule(note: subtree(:x)) { Note.new(x) }
      rule(call: subtree(:x), count: simple(:d)) { Dereference.new(x, count: d.to_i) }
      rule(call: subtree(:x)) { Dereference.new(x) }
      rule(chord: subtree(:x), count: simple(:d)) { Chord.new(x, count: d.to_i) }
      rule(chord: subtree(:x)) { Chord.new(x) }

      rule(assign: { name: simple(:n), value: subtree(:x) }) { Assignment.new(n, x)}
      rule(exec: subtree(:x)) { Exec.new(x) }

      rule(cmd: subtree(:x)) { Command.new(*x.first) }
      rule(filter: {name: simple(:n), args: subtree(:args), statements: subtree(:x)}) { Filter.new(n, args, x) }
    end

    def transformer
      @t ||= Transform.new
    end

    def parse_and_transform(text)
      text = text.dup
      text.strip!
      text << ';' unless text.end_with?(';')
      transformer.apply(parse(text))
    end
  end
end
