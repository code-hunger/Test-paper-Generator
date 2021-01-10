use lib '.';
use Problemlib;

my Template @templates = 'tasks'.IO.dir.sort.map: { template-from-file $_ };

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

$answers.say: "Name," ~ @templates>>.name.join(',');

for 'names.txt'.IO.lines -> $name {
    next unless $name.chars;

    $name.say;

    my Problem @problems = @templates.map: { make-problem $_ };

    my Str $file-name = "$name.tex";
    spurt "problems/$file-name", build-problem-set($template, $name, @problems);
    unless so compile-tex($file-name) {
        warn "Couldn't compile latex file for $name";
    }

    $answers.say: "$name, " ~ @problems.map(*.answer).join(',');
}

$answers.close;
