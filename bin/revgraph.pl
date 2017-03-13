#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Net::MQTT::Simple;
use Net::Graphite;

our $VERSION = "1.00"

# Setup mqtt connection
my $mqtt = Net::MQTT::Simple->new('revspace.nl');

# Setup mqtt connection
my $graphite = Net::Graphite->new(
     host                  => '127.0.0.1',
     port                  => 2003,
     trace                 => 0,                
     proto                 => 'tcp',
     timeout               => 1,
     fire_and_forget       => 1,
     return_connect_error  => 0
);

my %topics;

# "Connect" to graphite
$graphite->connect;


# subscribe to sensors with weird topics
$mqtt->subscribe(
	"revspace/sensors/+" => sub {
		my ($topic, $message) = @_;

		my $since = $topics{$topic} ? ( time() - $topics{$topic} ) : ( time() - 0 );

		my ($type) = $topic =~ /revspace\/sensors\/(.*)/;
		($message) = $message =~ m{(\d+(?:\.\d+)?)};

		my $graphite_path = "revgraph.sensor.$type.general";

		$graphite->send(
			path => $graphite_path,
			value => $message,
			time => time(),
		) unless $since > 1800;

		$topics{$topic} = time();
	}
);

# subscribe to standard sensor topics
$mqtt->subscribe(
	"revspace/sensors/+/+/+" => sub {
		my ($topic, $message) = @_;

		my $since = $topics{$topic} ? ( time() - $topics{$topic} ) : ( time() - 0 );

		my ($type, $room, $id) = $topic =~ /revspace\/sensors\/([^\/]+)\/([^\/]+)\/([^\/]+)/;
		($message) = $message =~ m{(\-?\d+(?:\.\d+)?)};

		my $graphite_path = "revgraph.sensor.$type.$room.$id";

		$graphite->send(
			path => $graphite_path,
			value => $message,
			time => time(),
		) unless $since > 1800;

		$topics{$topic} = time();
	}
);

# subscribe to open/closed space
$mqtt->subscribe(
	"revspace/state" => sub {
		my ($topic, $message) = @_;

		$message = $message eq 'open' ? 1 : 0;

		$graphite->send(
			path => "revgraph.state",
			value => $message,
			time => time(),
		);
	}
);

# Run this thing
$mqtt->run;

__END__

=head1 NAME

revgraph - turning the revspace mqtt stream into stats

=head1 DESCRIPTION

This is just a simple program that listens to mqtt topics from revspace and puts
them in to a graphite database. You can see the resulting graphs displayed by
grafana at: https://revgraph.bewaar.me/ 

=head1 LICENSE

The MIT License (MIT)

Copyright (c) 2017 Dave Olsthoorn

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
