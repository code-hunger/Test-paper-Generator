unit module Problemlib;

use MONKEY-SEE-NO-EVAL;

class Problem is export {
    has Str $.body;
    has Str $.answer;
}

class Template is export {
    has Str $.name;
    has Str $.body;
    has Str $.answer;
    has %.constraints;
    has @.non-zero;
}

sub template-from-file(IO::Path:D $file) is export {
    my %constraints;
    my @non-zero;
    my Str $answer = "";
    my Str $body;

    my @file-readers =
        sub read-constraint(Str:D $str) {
            if $str ~~ rx/^ (\S+) \s (\S+) \s (\S+) $/ {
                %constraints{$1.Str} = ($0.Int, $2.Int);
            } elsif $str ~~ rx/^ not0 \s (\S+) $/ {
                @non-zero.push($0.Str);
            } else {
                fail "Can't read constraint '$str'!";
            }
        },
        sub { $answer ~= $^a },
        sub { $body ~= $^a ~ "\n" };

    my Int $reader = 0;
    for $file.IO.lines -> $line {
        if $line.chars == 0 && $reader < @file-readers.elems - 1 {
            ++$reader;
            next
        }

        @file-readers[$reader]($line);
    }

    Template.new: :name($file.basename),
                  :$body, :$answer,
                  :%constraints, :@non-zero
}

sub make-problem(Template $template) is export {
    my Int %variables;

    for $template.constraints.kv -> $var,$constr {
        my Int $val;
        repeat { $val = ($constr[0] .. $constr[1]).rand.Int }
        while $template.non-zero.Set{$var} && $val == 0;

        %variables{$var} = $val;
    }

    sub insert-variables(Str:D $str is copy) {
        for %variables.kv -> $var, $value {
            $str ~~ s:g/$var/$value/
        }
        $str
    }

    my Str $answer = ~EVAL insert-variables($template.answer);

    my Str $body = $template.body;

    while $body ~~ m/ \{\{ ( <-[ \{ \} ]>+ ) \}\} / -> $match {
        my $template = ~EVAL insert-variables($match[0].Str);

        $body.substr-rw($match.from, $match.chars) = $template;
    }

    Problem.new: :$answer, :$body
}

sub build-problem-set(Str $template is copy,
                      Str $student-name,
                      Problem @problems) is export {
    my Str $problem-set =
        @problems.map('\begin{problem}' ~ *.body ~ '\end{problem}').join;

    given $template {
        s/'!student-name!'/$student-name/;
        s/'!problem-set!'/$problem-set/;
    }

    $template
}
