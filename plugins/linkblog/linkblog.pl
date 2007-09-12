## Copyright 2007 Six Apart, Ltd. See accompanying Linkblog.LICENSE file.

package MT::Plugin::Linkblog;
use strict;

use base qw( MT::Plugin );

use constant CONFIG_TEMPLATE => <<'TMPL';
<mtapp:setting
    id="linkblog"
    label="<__trans phrase="Link blog">"
    hint="<__trans phrase="If selected, the Link field will be available when editing entries on this blog.">"
    show_hint="1">
    <label><input type="checkbox" name="linkblog" id="linkblog" value="1"<mt:if name="linkblog"> checked="checked"</mt:if> /> Enable link blogging</label>
</mtapp:setting>
TMPL

our $VERSION = '1.3';

my $instance = __PACKAGE__->new(
    key            => 'linkblog',
    name           => 'Linkblog',
    version        => $VERSION,
    schema_version => 1,
    author_name    => 'Mark Paschal',
    author_link    => 'http://markpasc.org/mark/',
    description    => q(Customizes a blog for link blogging.),
    settings       => MT::PluginSettings->new(
        [ [ 'linkblog', { Default => 0, Scope => 'blog' } ], ]
    ),
    blog_config_template => CONFIG_TEMPLATE(),
);
MT->add_plugin($instance);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        object_types => {
            'linkbloglink' => 'Linkblog::Link',
        },
        callbacks => {
            'MT::App::CMS::template_param.edit_entry' =>
                sub { $plugin->enable_linkblogging(@_) },
            'MT::App::CMS::cms_post_save.entry' =>
                sub { $plugin->save_link_to_entry(@_) },
        },
        tags => {
            function => {
                'LinkblogUrl' => sub { $plugin->linkblog_url(@_) },
            },
        },
    });
}

sub blog_is_linkblog {
    my $plugin = shift;
    my ($blog) = @_;

    my $blog_id = ref $blog ? $blog->id : $blog;
    return $plugin->get_config_value('linkblog', "blog:$blog_id")
        ? 1 : 0;
}

sub save_link_to_entry {
    my $plugin = shift;
    my ($cb, $app, $obj, $original) = @_;

    return if !$obj->id;
    return if !$plugin->blog_is_linkblog($obj->blog_id);

    my $url = $app->{query}->param('url');
    return if !$url;

    require Linkblog::Link;
    my $link = Linkblog::Link->lookup($obj->id);
    if (!$link) {
        $link = Linkblog::Link->new;
        $link->id($obj->id);
    }

    $link->url($url);
    $link->save;
}

sub enable_linkblogging {
    my $plugin = shift;
    my ($cb, $app, $param, $tmpl) = @_;

    return if !$plugin->blog_is_linkblog($param->{blog_id});

    $plugin->add_url_field(@_);
    $plugin->add_entry_url(@_);
    $plugin->fill_fields_from_bookmarklet(@_);

    return;
}

sub fill_fields_from_bookmarklet {
    my $plugin = shift;
    my ($cb, $app, $param, $tmpl) = @_;

    return if $param->{id};  # only for new entries

    my $q = $app->{query};
    
    if (!$q->param('link_href') && $q->param('text') && $q->param('text') =~ m{ \A https?:// }xms) {
        ## Regular style bookmarklet.
        my $text = $q->param('text');
        if ($text =~ s{ \A (https?://[^<]+) <br/> <br/> }{}xms) {
            my $link_href = $1;
            
            $text =~ s{ ^ }{> }xmsg if $text;
            $param->{text} = $text;
            $param->{url} = $link_href;

            return;
        }

        ## Text didn't match... so try the new way. Won't hurt.
    }

    my %fields = (
        text  => 'text',
        url   => 'link_href',
        title => 'link_title',
    );

    FIELD: while (my ($param_field, $query_field) = each %fields) {
        my $value = $q->param($query_field) or next FIELD;
        $value =~ s{ ^ }{> }xmsg if $param_field eq 'text';
        $param->{$param_field} = $value;
    }

}

sub add_entry_url {
    my $plugin = shift;
    my ($cb, $app, $param, $tmpl) = @_;

    my $entry_id = $param->{id};
    return if !$entry_id;
    
    require Linkblog::Link;
    if (my $link = Linkblog::Link->lookup($entry_id)) {
        $param->{url} = $link->url;
        return;
    }

    if (my $url = $app->{query}->param('url')) {
        $param->{url} = $url;
    }

    return;
}

sub add_url_field {
    my $plugin = shift;
    my ($cb, $app, $param, $tmpl) = @_;

    my $tags = $tmpl->getElementById('tags')
        or die "No metad? wah\n";

    my $urlset = $tmpl->createElement('setvarblock');
    $urlset->setAttribute('name', 'url-app-setting');
    $urlset->innerHTML(<<'EOF');
        <mtapp:setting
            id="url"
            label="<__trans phrase="Link">">
            <div class="textarea-wrapper">
                <input name="url" id="url" class="full-width" tabindex="6" value="<mt:var name="url" escape="html">" autocomplete="off" />
            </div>
        </mtapp:setting>
EOF

    my $urlget = $tmpl->createElement('getvar');
    $urlget->setAttribute('name', 'url-app-setting');

    $tmpl->insertAfter($urlset, $tags);
    $tmpl->insertAfter($urlget, $urlset);
}

sub linkblog_url {
    my $plugin = shift;
    my ($ctx, $args, $cond) = @_;

    my $entry = $ctx->stash('entry')
        or return '';

    require Linkblog::Link;
    my $link = Linkblog::Link->lookup($entry->id)
        or return '';

    return $link->url || '';
}


1;

