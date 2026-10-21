\paper { indent = 0\mm short-indent = 0\mm ragged-right = ##f ragged-bottom = ##t ragged-last-bottom = ##t system-system-spacing.basic-distance = #25 system-system-spacing.minimum-distance = #20 system-system-spacing.padding = #10 system-system-spacing.stretchability = #0 markup-system-spacing.basic-distance = #5 top-system-spacing.basic-distance = #5 } \layout { \accidentalStyle forget \context { \Score \override TimeSignature.stencil = ##f \override BarNumber.stencil = ##f \override RehearsalMark.padding = #5.5 \override DynamicLineSpanner.direction = #UP \override DynamicText.extra-offset = #(cons 0 0.9) \override SpacingSpanner.uniform-stretching = ##t \override SpacingSpanner.strict-note-spacing = ##t \override SpacingSpanner.common-shortest-duration = #(ly:make-moment 1/4) } \context { \Lyrics \override VerticalAxisGroup.nonstaff-relatedstaff-spacing.padding = #1.8 } } \version "2.26.0"
#(set-global-staff-size 20)

% un-comment the next line to remove Lilypond tagline:
% \header { tagline="" }

% comment out the next line if you're debugging jianpu-ly
% (but best leave it un-commented in production, since
% the point-and-click locations won't go to the user input)
\pointAndClickOff

\paper {
  print-all-headers = ##t %% allow per-score headers

  % un-comment the next line for A5:
  % #(set-default-paper-size "a5" )

  % un-comment the next line for no page numbers:
  % print-page-number = ##f

  % un-comment the next 3 lines for a binding edge:
  % two-sided = ##t
  % inner-margin = 20\mm
  % outer-margin = 10\mm

  % un-comment the next line for a more space-saving header layout:
  % scoreTitleMarkup = \markup { \center-column { \fill-line { \magnify #1.5 { \bold { \fromproperty #'header:dedication } } \magnify #1.5 { \bold { \fromproperty #'header:title } } \fromproperty #'header:composer } \fill-line { \fromproperty #'header:instrument \fromproperty #'header:subtitle \smaller{\fromproperty #'header:subsubtitle } } } }

  % As jianpu-ly was run on a Mac, we include a Mac fonts workaround.
  % The Mac version of Lilypond 2.18 used Arial Unicode MS as a
  % fallback even in the Serif font, but 2.20 drops this in Serif
  % (using it only in Sans), which means any Serif text (titles,
  % lyrics etc) that includes Chinese will likely fall back to
  % Japanese fonts which don't support all Simplified hanzi.
  % This brings back 2.18's behaviour on 2.20+:
  property-defaults.fonts.serif = "Source Serif Pro,Source Han Serif SC,Times New Roman,Arial Unicode MS"

  % Might need to enforce a minimum spacing between systems, especially if lyrics are below the last staff in a system and numbers are on the top of the next
  system-system-spacing = #'((basic-distance . 7) (padding . 5) (stretchability . 1e7))
  score-markup-spacing = #'((basic-distance . 9) (padding . 5) (stretchability . 1e7))
  score-system-spacing = #'((basic-distance . 9) (padding . 5) (stretchability . 1e7))
  markup-system-spacing = #'((basic-distance . 2) (padding . 2) (stretchability . 0))
}

%% 2-dot and 3-dot articulations
#(append! default-script-alist
   (list
    `(two-dots
       . (
           (script-priority . -200)
           (stencil . ,ly:text-interface::print)
           (text . ,#{ \markup \override #'(font-encoding . latin1) \center-align \bold ":" #})
           (padding . 0.20)
           (avoid-slur . inside)
           (side-axis . ,Y)
           (direction . ,UP)))))
#(append! default-script-alist
   (list
    `(three-dots
       . (
           (script-priority . -200)
           (stencil . ,ly:text-interface::print)
           (text . ,#{ \markup \override #'(font-encoding . latin1) \center-align \bold "⋮" #})
           (padding . 0.30)
           (avoid-slur . inside)
           (side-axis . ,Y)
           (direction . ,UP)))))
"two-dots" =
#(make-articulation 'two-dots)

"three-dots" =
#(make-articulation 'three-dots)

\layout {
  \context {
    \Score
    scriptDefinitions = #default-script-alist
  }
}

note-mod =
#(define-music-function
     (text note)
     (markup? ly:music?)
   #{
     \tweak NoteHead.stencil #ly:text-interface::print
     \tweak NoteHead.text
        \markup \lower #0.5 \sans \bold #text
     \tweak Rest.stencil #ly:text-interface::print
     \tweak Rest.text
        \markup \lower #0.5 \sans \bold #text
     #note
   #})
#(define (flip-beams grob)
   (ly:grob-set-property!
    grob 'stencil
    (ly:stencil-translate
     (let* ((stl (ly:grob-property grob 'stencil))
            (centered-stl (ly:stencil-aligned-to stl Y DOWN)))
       (ly:stencil-translate-axis
        (ly:stencil-scale centered-stl 1 -1)
        (* (- (car (ly:stencil-extent stl Y)) (car (ly:stencil-extent centered-stl Y))) 0) Y))
     (cons 0 -0.8))))

%=======================================================
#(define-event-class 'jianpu-grace-curve-event 'span-event)

#(define (add-grob-definition grob-name grob-entry)
   (set! all-grob-descriptions
         (cons ((@@ (lily) completize-grob-entry)
                (cons grob-name grob-entry))
               all-grob-descriptions)))

#(define (jianpu-grace-curve-stencil grob)
   (let* ((elts (ly:grob-object grob 'elements))
          (refp-X (ly:grob-common-refpoint-of-array grob elts X))
          (X-ext (ly:relative-group-extent elts refp-X X))
          (refp-Y (ly:grob-common-refpoint-of-array grob elts Y))
          (Y-ext (ly:relative-group-extent elts refp-Y Y))
          (direction (ly:grob-property grob 'direction RIGHT))
          (x-start (* 0.5 (+ (car X-ext) (cdr X-ext))))
          (y-start (+ (car Y-ext) 0.32))
          (x-start2 (if (eq? direction RIGHT)(+ x-start 0.5)(- x-start 0.5)))
          (x-end (if (eq? direction RIGHT)(+ (cdr X-ext) 0.2)(- (car X-ext) 0.2)))
          (y-end (- y-start 0.5))
          (stil (ly:make-stencil `(path 0.1
                                        (moveto ,x-start ,y-start
                                         curveto ,x-start ,y-end ,x-start ,y-end ,x-start2 ,y-end
                                         lineto ,x-end ,y-end))
                                  X-ext
                                  Y-ext))
          (offset (ly:grob-relative-coordinate grob refp-X X)))
     (ly:stencil-translate-axis stil (- offset) X)))

#(add-grob-definition
  'JianpuGraceCurve
  `(
     (stencil . ,jianpu-grace-curve-stencil)
     (meta . ((class . Spanner)
              (interfaces . ())))))

#(define jianpu-grace-curve-types
   '(
      (JianpuGraceCurveEvent
       . ((description . "Used to signal where curve encompassing music start and stop.")
          (types . (general-music jianpu-grace-curve-event span-event event))
          ))
      ))

#(set!
  jianpu-grace-curve-types
  (map (lambda (x)
         (set-object-property! (car x)
           'music-description
           (cdr (assq 'description (cdr x))))
         (let ((lst (cdr x)))
           (set! lst (assoc-set! lst 'name (car x)))
           (set! lst (assq-remove! lst 'description))
           (hashq-set! music-name-to-property-table (car x) lst)
           (cons (car x) lst)))
    jianpu-grace-curve-types))

#(set! music-descriptions
       (append jianpu-grace-curve-types music-descriptions))

#(set! music-descriptions
       (sort music-descriptions alist<?))


#(define (add-bound-item spanner item)
   (if (null? (ly:spanner-bound spanner LEFT))
       (ly:spanner-set-bound! spanner LEFT item)
       (ly:spanner-set-bound! spanner RIGHT item)))

jianpuGraceCurveEngraver =
#(lambda (context)
   (let ((span '())
         (finished '())
         (current-event '())
         (event-start '())
         (event-stop '()))
     `(
       (listeners
        (jianpu-grace-curve-event .
          ,(lambda (engraver event)
             (if (= START (ly:event-property event 'span-direction))
                 (set! event-start event)
                 (set! event-stop event)))))

       (acknowledgers
        (note-column-interface .
          ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (begin
                  (ly:pointer-group-interface::add-grob span 'elements grob)
                  (add-bound-item span grob)))
             (if (ly:spanner? finished)
                 (begin
                  (ly:pointer-group-interface::add-grob finished 'elements grob)
                  (add-bound-item finished grob)))))
        (inline-accidental-interface .
          ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (begin
                  (ly:pointer-group-interface::add-grob span 'elements grob)))
             (if (ly:spanner? finished)
                 (ly:pointer-group-interface::add-grob finished 'elements grob))))
        (script-interface .
          ,(lambda (engraver grob source-engraver)
             (let ((is-dyn (or (grob::has-interface grob 'dynamic-interface)
                       (eq? (ly:grob-property grob 'meta) 'DynamicText))))
               (if (and (ly:spanner? span) (not is-dyn))
                (ly:pointer-group-interface::add-grob span 'elements grob))
               (if (and (ly:spanner? finished) (not is-dyn))
                (ly:pointer-group-interface::add-grob finished 'elements grob))))))
       (process-music .
         ,(lambda (trans)
            (if (ly:stream-event? event-stop)
                (if (null? span)
                    (ly:warning "No start to this curve.")
                    (begin
                     (set! finished span)
                     (ly:engraver-announce-end-grob trans finished event-start)
                     (set! span '())
                     (set! event-stop '()))))
            (if (ly:stream-event? event-start)
                (begin
                 (set! span (ly:engraver-make-grob trans 'JianpuGraceCurve event-start))
                 (set! event-start '())))))
       
       (stop-translation-timestep .
         ,(lambda (trans)
            (if (and (ly:spanner? span)
                     (null? (ly:spanner-bound span LEFT)))
                (ly:spanner-set-bound! span LEFT
                  (ly:context-property context 'currentMusicalColumn)))
            (if (ly:spanner? finished)
                (begin
                 (if (null? (ly:spanner-bound finished RIGHT))
                     (ly:spanner-set-bound! finished RIGHT
                       (ly:context-property context 'currentMusicalColumn)))
                 (set! finished '())
                 (set! event-start '())
                 (set! event-stop '())))))
       
       (finalize
        (lambda (trans)
          (if (ly:spanner? finished)
              (begin
               (if (null? (ly:spanner-bound finished RIGHT))
                   (set! (ly:spanner-bound finished RIGHT)
                         (ly:context-property context 'currentMusicalColumn)))
               (set! finished '())))))
       )))

jianpuGraceCurveStart =
#(make-span-event 'JianpuGraceCurveEvent START)

jianpuGraceCurveEnd =
#(make-span-event 'JianpuGraceCurveEvent STOP)
%===========================================================

%{ The jianpu-ly input was:
title=A Thousand Years
subtitle=Christina Perri
SeparateTimesig
NoIndent
1=Bb
6/8
tempo=46

3. 3. | 3. 2. | 3. 3. | 3. 2. | 4. 4. | 4. 1. | 3. 3. | 2. q1 q7, q5, | \break
\bar ".|:-|" 1. 1. | 1. s3 q2. q1 | 1. 1. | 1. q5 s4 q3. | \break 
1. q5 s4 q3. | q2. q3. q7,. q7,. | 1. 1. | 1 s0 s1 s3 q2. q1 | \break
1. 1. | 1. q5 s4 q3. | 1. q5 s4 q3. | q2. q3. q7,. q1. | \break
6, - - | 6. 7.  | 1' - - | 7 - - | q3 s5 q3. q3 s5 q3. | \break
6 q5 q2 1 | q3 s5 q3. q3 s5 q3. | 6 q5 q2 q1 s1 s2 | \break
4 - q3 q6, ( | 6, ) s0 s6, s1 q2 q1 s2 | 4. 3. | \break
2 - - | q3 s5 q3. q3 s5 q3. | \bar ":|." 5. 1'. | 7. 5. | \bar ":|." \break

L: _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ Heart beats fast, co- lors and pro- mi- ses. How to be brave? How can I love when I'm af- raid to fall? But watch- ing you stand a- lone. All of my doubt sud- den- ly goes a- way some- how. One step clo- ser. I have died eve- ry day wait- ing for you. Dar- ling, don't be af- raid, I have loved you for a thou- sand years. I'll love you for a thou- sand more. I have died eve- ry day
L: _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ Time stands still, beau- ty in all she is. I will be brave, I will not let a- ny- thing take a- way. What's stand- ing in front of me. E- ve- ry breath, e- ve- ry hour has come to this.
%}


\score {
<< \override Score.BarNumber.break-visibility = #center-visible
\override Score.BarNumber.Y-offset = -1
\set Score.barNumberVisibility = #(every-nth-bar-number-visible 5)

%% === BEGIN JIANPU STAFF ===
    \new RhythmicStaff \with {
    \consists "Accidental_engraver" 
    \consists \jianpuGraceCurveEngraver
    % Get rid of the stave but not the barlines:
    \override StaffSymbol.line-count = #0 % tested in 2.15.40, 2.16.2, 2.18.0, 2.18.2, 2.20.0 and 2.22.2
    \override BarLine.bar-extent = #'(-2 . 2) % LilyPond 2.18: please make barlines as high as the time signature even though we're on a RhythmicStaff (2.16 and 2.15 don't need this although its presence doesn't hurt; Issue 3685 seems to indicate they'll fix it post-2.18)
    $(add-grace-property 'Voice 'Stem 'direction DOWN)
    $(add-grace-property 'Voice 'Slur 'direction UP)
    $(add-grace-property 'Voice 'Stem 'length-fraction 0.5)
    $(add-grace-property 'Voice 'Beam 'beam-thickness 0.1)
    $(add-grace-property 'Voice 'Beam 'length-fraction 0.3)
    $(add-grace-property 'Voice 'Beam 'after-line-breaking flip-beams)
    $(add-grace-property 'Voice 'Beam 'Y-offset 2.5)
    $(add-grace-property 'Voice 'NoteHead 'Y-offset 2.5)
    }
    { \new Voice="Y" {
    \override Beam.transparent = ##f
    \override Stem.direction = #DOWN
    \override Tie.staff-position = #2.5
    \tupletUp
    \tieUp
    \override Stem.length-fraction = #0.5
    \override Beam.beam-thickness = #0.1
    \override Beam.length-fraction = #0.5
    \override Beam.after-line-breaking = #flip-beams
    \override Voice.Rest.style = #'neomensural % this size tends to line up better (we'll override the appearance anyway)
    \override Accidental.font-size = #-4
    \override TupletBracket.bracket-visibility = ##t

    \override Staff.TimeSignature.style = #'numbered
    \override Staff.Stem.transparent = ##t
    \override Staff.TimeSignature.stencil = ##f
 \once \override Score.RehearsalMark.self-alignment-X = #LEFT \mark \markup{1=B\flat 6/8}
\time 6/8  \note-mod "3" e4.  \note-mod "3" e4. | | %{ bar 2: %}
 \note-mod "3" e4.
 \note-mod "2" d4. | | %{ bar 3: %}
 \note-mod "3" e4.
 \note-mod "3" e4. | | %{ bar 4: %}
 \note-mod "3" e4.
 \note-mod "2" d4. | | %{ bar 5: %}
 \note-mod "4" f4.
 \note-mod "4" f4. | | %{ bar 6: %}
 \note-mod "4" f4.
 \note-mod "1" c4. | | %{ bar 7: %}
 \note-mod "3" e4.
 \note-mod "3" e4. | | %{ bar 8: %}
 \note-mod "2" d4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "7" b8-\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
| \break \bar ".|:-|" | %{ bar 9: %}
 \note-mod "1" c4.
 \note-mod "1" c4. | | %{ bar 10: %}
 \note-mod "1" c4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #2
 \note-mod "3" e16[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "2" d8.
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
| | %{ bar 11: %}
 \note-mod "1" c4.
 \note-mod "1" c4. | | %{ bar 12: %}
 \note-mod "1" c4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "4" f16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| \break | %{ bar 13: %}
 \note-mod "1" c4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "4" f16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| | %{ bar 14: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8.[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "7" b8.-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "7" b8.-\tweak #'X-offset #0.6 _. ]
| | %{ bar 15: %}
 \note-mod "1" c4.
 \note-mod "1" c4. | | %{ bar 16: %}
 \note-mod "1" c4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #2
 \note-mod "0" r16[
\set stemLeftBeamCount = #2
\set stemRightBeamCount = #2
 \note-mod "1" c16]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #2
 \note-mod "3" e16[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "2" d8.
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
| \break | %{ bar 17: %}
 \note-mod "1" c4.
 \note-mod "1" c4. | | %{ bar 18: %}
 \note-mod "1" c4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "4" f16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| | %{ bar 19: %}
 \note-mod "1" c4.
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "4" f16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| | %{ bar 20: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8.[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "7" b8.-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8.]
| \break \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 21: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4 | | %{ bar 22: %}
 \note-mod "6" a4.
 \note-mod "7" b4. | \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 23: %}
 \note-mod "1" c4^.
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" c4
 ~  \note-mod "–" c4 | \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 24: %}
 \note-mod "7" b4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" b4
 ~  \note-mod "–" b4 | | %{ bar 25: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| \break | %{ bar 26: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
]   \note-mod "1" c4 | | %{ bar 27: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| | %{ bar 28: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "1" c16
\set stemLeftBeamCount = #2
\set stemRightBeamCount = #2
 \note-mod "2" d16]
| \break \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 29: %}
 \note-mod "4" f4
 ~  \note-mod "–" f4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
( | | %{ bar 30: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
) \set stemLeftBeamCount = #0
\set stemRightBeamCount = #2
 \note-mod "0" r16[
\set stemLeftBeamCount = #2
\set stemRightBeamCount = #2
 \note-mod "6" a16-\tweak #'X-offset #0.6 _. ]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #2
 \note-mod "1" c16[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "2" d8
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "2" d16]
| | %{ bar 31: %}
 \note-mod "4" f4.
 \note-mod "3" e4. | \break \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 32: %}
 \note-mod "2" d4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" d4
 ~  \note-mod "–" d4 | | %{ bar 33: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "5" g16
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8.]
| \bar ":|." | %{ bar 34: %}
 \note-mod "5" g4.
 \note-mod "1" c4.^. | | %{ bar 35: %}
 \note-mod "7" b4.
 \note-mod "5" g4. | \bar ":|." \break \bar "|." } }
% === END JIANPU STAFF ===

\new Lyrics = "IZ" { \lyricsto "Y" { _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ Heart beats fast, co --
lors and pro --
mi --
ses. How to be brave? How can I love when I'm af --
raid to fall? But watch --
ing you stand a --
lone. All of my doubt sud --
den --
ly goes a --
way some --
how. One step clo --
ser. I have died eve --
ry day wait --
ing for you. Dar --
ling, don't be af --
raid, I have loved you for a thou --
sand years. I'll love you for a thou --
sand more. I have died eve --
ry day } } \new Lyrics = "Ia" { \lyricsto "Y" { _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ Time stands still, beau --
ty in all she is. I will be brave, I will not let a --
ny --
thing take a --
way. What's stand --
ing in front of me. E --
ve --
ry breath, e --
ve --
ry hour has come to this. } } 
>>
\header{
title="A Thousand Years"
subtitle="Christina Perri"
tempo="46"
}
\layout{ indent = 0.0 
  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }
} }
\score {
\unfoldRepeats
<< 

% === BEGIN MIDI STAFF ===
    \new Staff { \new Voice="b" { \transpose c bes, { \key c \major  \time 6/8 e'4. e'4. | | %{ bar 2: %} e'4. d'4. | | %{ bar 3: %} e'4. e'4. | | %{ bar 4: %} e'4. d'4. | | %{ bar 5: %} f'4. f'4. | | %{ bar 6: %} f'4. c'4. | | %{ bar 7: %} e'4. e'4. | | %{ bar 8: %} d'4. c'8 b8 g8 | \break \bar ".|:-|" | %{ bar 9: %} c'4. c'4. | | %{ bar 10: %} c'4. e'16 d'8. c'8 | | %{ bar 11: %} c'4. c'4. | | %{ bar 12: %} c'4. g'8 f'16 e'8. | \break | %{ bar 13: %} c'4. g'8 f'16 e'8. | | %{ bar 14: %} d'8. e'8. b8. b8. | | %{ bar 15: %} c'4. c'4. | | %{ bar 16: %} c'4 r16 c'16 e'16 d'8. c'8 | \break | %{ bar 17: %} c'4. c'4. | | %{ bar 18: %} c'4. g'8 f'16 e'8. | | %{ bar 19: %} c'4. g'8 f'16 e'8. | | %{ bar 20: %} d'8. e'8. b8. c'8. | \break | %{ bar 21: %} a2. | | %{ bar 22: %} a'4. b'4. | | %{ bar 23: %} c''2. | | %{ bar 24: %} b'2. | | %{ bar 25: %} e'8 g'16 e'8. e'8 g'16 e'8. | \break | %{ bar 26: %} a'4 g'8 d'8 c'4 | | %{ bar 27: %} e'8 g'16 e'8. e'8 g'16 e'8. | | %{ bar 28: %} a'4 g'8 d'8 c'8 c'16 d'16 | \break | %{ bar 29: %} f'2 e'8 a8 ( | | %{ bar 30: %} a4 ) r16 a16 c'16 d'8 c'8 d'16 | | %{ bar 31: %} f'4. e'4. | \break | %{ bar 32: %} d'2. | | %{ bar 33: %} e'8 g'16 e'8. e'8 g'16 e'8. | \bar ":|." | %{ bar 34: %} g'4. c''4. | | %{ bar 35: %} b'4. g'4. | \bar ":|." \break } } }
% === END MIDI STAFF ===

>>
\header{
title="A Thousand Years"
subtitle="Christina Perri"
tempo="46"
}
\midi { \context { \Score tempoWholesPerMinute = #(ly:make-moment 84/4)}} }
