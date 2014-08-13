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


    class Transform < Parslet::Transform
      rule(note: subtree(:x))   { Note.new(x) }
      rule(chord: sequence(:x)) { Chord.new(x) }
      rule(notes: sequence(:x)) { NoteList.new(x) }
    end

    def transformer
      @t ||= Transform.new
    end

    def parse_and_transform(text)
      text << ';' unless text.end_with?(';')
      transformer.apply(parse(text))
    end
  end
end
