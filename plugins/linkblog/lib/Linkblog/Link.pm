
package Linkblog::Link;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        id  => 'integer not null auto_increment',
        url => 'string(255)',
    },
    indexes => {
        id => 1,
    },
    primary_key => 'id',
    datasource  => 'links',
});


1;

