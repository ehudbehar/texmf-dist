#! /usr/bin/env perl
#  deweb v1.2, kills the C sections of a CWEB file, for passing to ChkTeX.
#  Copyright (C) 1996 Jens T. Berger Thielemann
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
#  Contact the author at:
#		Jens Berger
#		Spektrumvn. 4
#		N-0666 Oslo
#		Norway
#		E-mail: <jensthi@ifi.uio.no>
#
#
#

print STDERR "DeWEB v1.3 - Copyright 1996 Jens T. Berger Thielemann\n";

undef $/;
my @FILES = @ARGV;
FILE:
while( my $file = shift @FILES ) {

    my $success = open my $fh, '<', "$file";
    if ( ! $success ) {
        print STDERR "Couldn't open file '$file'\n";
        next FILE;
    }

    $texmode = 1;
    $_ = <$fh>;

    while (/\@/) {
        &out($`);
        $_ = $';

        if (/^@/) {
            $_ = $';
            &out('@');
            next;
        }

        if (/^([\s\n])/) {
            $_ = $';
            print "\n" if $1 eq "\n";
            $texmode = 1;
            next;
        }

        if (/^[cpd]/i) {
            $_ = $';
            $texmode = 0;
            next;
        }

        if (/^\,/i) {
            $_ = $';
            print '\,';
            next;
        }

        if (m!^/!) {
            $_ = $';
            print '\\\\';
            next;
        }

        if (/^[h\&\|\;\#\+]/i || /^i.*/i) {
            $_ = $';
            next;
        }

        if (/^\*[0-9\*]?((.|\n)*?\.)/) {
            $_ = $';
            print $1;
            $texmode = 1;
            next;
        }

        if (/^[<(^.t!]((.|\n)*?)\@\>/i) {
            $_ = $';
            print '{'.$1.'}';
            $texmode = 0;
            next;
        }

        if (/^[=]((.|\n)*?)\@\>/) {
            $_ = $';
            print &printnl($1);
            next;
        }

        if (/^[fsl](\s+\S+\s+\S+)|^\'(.|\n)*?\'|^\[((.|\n)*?)\@\]/i) {
            $_ = $';
            print &printnl($+);
            next;
        }

        @line = split(/\n/, $_, 2);
        print STDERR "Unknown opcode, ignored. Buffer:\n$line[0]\n";

    }

    print $_;

}

sub printnl {
    my($foo);
    if (defined $_[0]) {
        $foo = $_[0];
        $foo =~ s/.//g;
    } else {
        $foo = "";
    }
    $foo;
}

sub out {
    print $texmode? $_[0] : &printnl($_[0]);
}
