#!/usr/bin/env ruby
require 'parslet'

class Parser < Parslet::Parser
  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }
  rule(:comma)  { str(',') }
  rule(:caret)  { str('^') }
  rule(:plus)   { str('+') }
  rule(:minus)  { str('-') }
  rule(:lt)     { str('<') }
  rule(:gt)     { str('>') }

  rule(:space)  { match("\s").repeat(1) }
  rule(:space?) { space.maybe }

  rule(:number)        { match('[0-9]').repeat(1) }
  rule(:plus_or_minus) { plus | minus }
  rule(:signed_number) { plus_or_minus.maybe >> number }

  root(:program)

  rule(:program) { stmt.repeat(0) }
  rule(:stmt)    { space? >> expr >> space? >> str(';') }
  rule(:expr)    { note_list.as(:notes) | chord.as(:chord) }

  rule(:chord)     { lt >> note_list >> gt }
  rule(:note_list) { note.as(:note).repeat(1) }
  rule(:note)      { name.as(:name) >> octave.maybe >> timing.maybe >> space? }

  rule(:name)          { letter >> sharp_or_flat.maybe }
  rule(:letter)        { match('[A-G]') }
  rule(:sharp_or_flat) { match('[#b]')  }

  rule(:octave) { caret >> signed_number.as(:octave) }
  rule(:timing) { comma >> number.as(:timing) }

end

class Note
  attr_reader :name, :octave, :timing

  def initialize(n, o, t)
    @name   = n
    @octave = o
    @timing = ([:timing] || 1).to_i
  end
end

class Transform < Parslet::Transform
  rule(
    name:   simple(:name),
    octave: simple(:octave),
    timing: simple(:timing)
  ) do
    Note.new(name, octave, timing)
  end
end
