use ExtUtils::MakeMaker;

WriteMakefile(
  NAME            => 'RevGraph',
  VERSION_FROM    => 'bin/revgraph.pl',
  ABSTRACT_FROM   => 'bin/revgraph.pl',
  EXE_FILES       => [ 'bin/revgraph.pl' ],
  PREREQ_PM       => {
    "Net::MQTT::Simple" => 0,
    "Net::Graphite"     => 0
  },
  LICENSE         => 'mit',
  AUTHOR          => 'Dave Olsthoorn <dave@bewaar.me>'
);
