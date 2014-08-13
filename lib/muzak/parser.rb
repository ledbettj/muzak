require 'parslet'
require 'muzak/objects'

module Muzak
  class Parser < Parslet::Parser
    rule(:lparen) { str('(') }
    rule(:rparen) { str(')') }
    rule(:comma)  { str(',') }
    rule(:caret)  { str('^') }
    rule(:plus)   { str('+') }
    rule(:minus)  { str('-') }
    rule(:lt)     { str('<') }
    rule(:gt)     { str('>') }
    rule(:at)     { str('@') }
    rule(:eq)     { str('=') }
    rule(:let)    { str('let') }
    rule(:lsquare){ str('[') }
    rule(:rsquare){ str(']') }

    rule(:space)  { match("\s").repeat(1) }
    rule(:space?) { space.maybe }

    rule(:number)        { match('[0-9]').repeat(1) }
    rule(:plus_or_minus) { plus | minus }
    rule(:signed_number) { plus_or_minus.maybe >> number }
    rule(:identifier)    { match('[A-Za-z]') >> match('[A-Za-z0-9_]').repeat(0) }

    root(:program)

    rule(:program) { stmt.repeat(0) }
    rule(:stmt)    { space? >> expr >> space? >> repeater.maybe >> space? >> str(';') }
    rule(:expr)    { note_list.as(:notes) | chord.as(:chord) | cmd.as(:command) | assignment.as(:assignment) | invocation.as(:invocation) }

    rule(:chord)     { lt >> note_list >> gt }
    rule(:note_list) { note.as(:note).repeat(1) }
    rule(:note)      { name.as(:name) >> octave.maybe >> timing.maybe >> space? }

    rule(:cmd) { at >> match('[A-Za-z]').repeat(1).as(:command) >> lparen >> space? >> number.as(:value) >> space? >> rparen }
    rule(:assignment) { let >> space >> identifier.as(:identifier) >> space? >> eq >> space? >> chord.as(:chord) }
    rule(:invocation) { lsquare >> space? >> identifier.as(:identifier) >> space? >> rsquare }
    rule(:name)          { letter >> sharp_or_flat.maybe }
    rule(:letter)        { match('[A-G_]') }
    rule(:sharp_or_flat) { match('[#b]')  }

    rule(:octave) { caret >> signed_number.as(:octave) }
    rule(:timing) { comma >> number.as(:timing) }

    rule(:repeater) { str('x') >> number.as(:count) }

    class Transform < Parslet::Transform
      rule(note: subtree(:x))   { Note.new(x) }
      rule(chord: sequence(:x)) { Chord.new(x) }
      rule(chord: sequence(:x), count: simple(:d)) { Chord.new(x, count: d.to_i) }
      rule(notes: sequence(:x)) { NoteList.new(x) }
      rule(notes: sequence(:x), count: simple(:d)) { NoteList.new(x, count: d.to_i) }
      rule(assignment: subtree(:x)) { Assignment.new(x) }
      rule(command: subtree(:x)) { Command.new(x) }
      rule(invocation: subtree(:x)) { Invocation.new(x) }
      rule(invocation: subtree(:x), count: simple(:d)) { Invocation.new(x, count: d.to_i) }
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
