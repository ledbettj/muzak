#!/usr/bin/env ruby
require 'parslet'

class Parser < Parslet::Parser
  rule(:lparen) { str('(') }
  rule(:rparen) { str(')') }
  rule(:comma)  { str(',') }
  rule(:caret)  { str('^') }
  rule(:plus)   { str('+') }
  rule(:minus)  { str('-') }
  rule(:space)  { match("\s").repeat(1) }
  rule(:space?) { space.maybe }

  rule(:number) { match('[0-9]').repeat(1) }

  rule(:p_or_m) { plus | minus }

  rule(:timing) { comma >> number }
  rule(:octave) { caret >> p_or_m.maybe >> number }

  rule(:letter) { match('[A-G]') }
  rule(:s_or_f) { match('[#b]')  }
  rule(:name)   { letter >> s_or_f.maybe }

  rule(:note)   { name >> octave.maybe >> timing.maybe >> space? }

  rule(:note_list) { note.repeat(1) }
  rule(:group) { lparen >> space? >> note_list >> rparen >> space? }

  rule(:expr) { note_list | group }
  rule(:program) { expr.repeat(0) }

  root(:program)
end
