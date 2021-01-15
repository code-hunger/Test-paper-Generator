use lib '.';
use Problemlib;

my Template @templates = 'tasks'.IO.dir.sort.map: &template-from-file;

my $answers = open 'answers.csv', :w;

mkdir 'problems';
mkdir 'problems/out';
mkdir 'problems/pdfs';

my Str $template = 'template.tex'.IO.slurp;

sub compile-tex {
    run('pdflatex',
        '-interaction=nonstopmode',
        '-output-directory=out',
        $^file,
        :cwd('problems'),
        :out('/dev/null'))
}

my &join-csv = *.join(',');

$answers.say: "Name," ~ join-csv @templates>>.name;

for 'names.txt'.IO.lines -> $name {
    next unless $name.chars;

    $name.say;

    my Problem @problems = @templates.map: &make-problem;

    my Str $file-name = "$name.tex";
    spurt "problems/$file-name", build-problem-set($template, $name, @problems);
    unless so compile-tex($file-name) {
        warn "Couldn't compile latex file for $name."
              ~ "Look at 'problems/out/$name.log' for details.";
        if prompt("Continue? [Y/n]: ").lc eq 'n' { last } else { next  }
    }

    move "problems/out/$name.pdf", "problems/pdfs/$name.pdf";

    $answers.say: "$name," ~ join-csv @problems>>.answer;
}

$answers.close;
