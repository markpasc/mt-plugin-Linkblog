#!/usr/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'MT::Plugin::Linkblog',
    VERSION_FROM    => 'plugins/linkblog/linkblog.pl',
    DISTNAME        => 'linkblog',
);

