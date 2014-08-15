Muzak
============

Muzak is a dumb little toy scripting language for making sounds.

Usage
------------

    git clone https://github.com/ledbettj/muzak.git
    cd muzak
    bundle install

You can then run Muzak either interactively, or by providing files to play:

    bundle exec ./bin/muzak             # start an interactive session
    bundle exec ./bin/muzak ./my.muzak  # play file and exit
    bundle exec ./bin/muzak <./my.muzak # same as above

Besides file names, you can also specify the following arguments:

    --bpm=<bpm>    # Set the number of beats per minute.  This affects the
                   # duration of Whole notes, quarter notes, etc.
                   # Default is 240 BPM.
    --octave=<o>   # Set the default octave, from 0-12.  Default is 4.


Syntax
------------

### Notes

The simplest element is a Note, which is A-G and sharp (`F#`) or
flat (`Db`) variants.

    A

A note can also have an octave adjustment. For example, the `A` above
would be 440Hz by default.  We can play an `A` an octave lower (220Hz) like so:

    A^-1

Or an octave higher:

    A^1

Since we didn't specify, these notes are Whole notes: at 240 BPM, they would last
1 second.  We can specify a quarter note like so:

    A,4

or an 8th note:

    A,8

You can provide any timing here, for example 1/14th of a whole note:

    A,14

And of course, you can combine with the octave adjustment:

    A^-1,16

There's a special note `_` which indicates silence, for example resting for a
quarter note:

    _,4

### Sequences of notes and repetition.

In order to play more than one thing, you must seperate them with either a `;`
or a __new line__.  For example, "Hot Cross Buns":

    B ; A; G; _
    B ; A; G; _
    G,4 ; G,4 ; G,4 ; G,4
    A,4 ; A,4 ; A,4 ; A,4
    B ; A; G; _

Obviously, this is super verbose and repetitive.  We can repeat notes by
specifying a repeater:

    B ; A; G; _
    B ; A; G; _
    G,4 x4
    A,4 x4
    B ; A; G; _

But that only gets us part of the way there.  You can group notes with
square brackets, and then repeat them:

    [B A G _] x2
    G,4 x4
    A,4 x4
    [B A G _]

But we've still repeated `B A G _` twice.  We can use a variable to save it
and use it again.

`let` assigns a note or sequence of notes to a variable.
You can play that variable by using parenthesis around it's name.

    let phrase = [B A G _]
    (phrase) x2
    G,4 x4
    A,4 x4
    (phrase)


### Chords

Up until now, we've only been playing one note at a time.  We can also
play multiple notes at once with chords, which are specified with angular
brackets.  For example, to play an A minor, followed by a C, followed by a D:

    <A C E> ; <C E G> ; <D F# A>;

We can adjust the timing or octave of a chord, just like a note:

    <A C E>^-1,4

Or adjust the octave of the individual notes inside a chord:

    <A^1 C E>

Or both:

    <A^1 C E>^-1,4

We can also use chords inside lists or as variables:

    let Am = <A C E>
    let chorus = [(Am) E D E <C E G>]
    (chorus)

For your convenience, muzak predefines the following chord variables:

    let C   = <C E G>
    let Cm  = <C Eb G>
    let D   = <D F# A>
    let Dm  = <D F A>
    let E   = <E G# B>
    let Em  = <E G B>
    let F   = <F A C>
    let Fm  = <F Ab C>
    let G   = <G B D>
    let Gm  = <G Bb D>
    let A   = <A C# E>
    let Am  = <A C E>
    let A7  = <A C# E G>

### Audio Filters

What if you could make this thing sound less crappy? That would be cool, right?
Well you can't.  But you can do basic audio filters.

Filters have a block form that looks like this:

    |compress { C; A; D;}

or to pass arguments:

    |compress(threshold=0.5, scale=0.25) { C; A; D;}


Right now the only filters available are:

* `null` - does nothing.
* `clip` - clips values above `threshold` or below `-threshold`.
* `compress` - like `clip`, but instead of setting automatically to +/- threshold, it instead
scales the amount above the threshold by `scale`.  For example, given a threshold of 3, a scale of 1/4, and a value of 7, we would compute the new value to be (7 - 3) * 1/4 + 3 = 4.
* `distort` - multiplies the values by `scale` and then clips them to `1.0`.

### Other commands

Besides playing notes or chords or assigning variables, there are a few other
commands.

* Raise current octave by one: `^^`
* Lower current octave by one: `vv`
* Set the current octave to 4: `@4`
* Set the BPM to 120:          `%120`

