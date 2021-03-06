## Copyright 2007 Six Apart, Ltd. See accompanying Linkblog.LICENSE file.

package Linkblog;
use strict;

sub blog_is_linkblog {
    my $class = shift;
    my ($blog) = @_;

    my $blog_id = ref $blog ? $blog->id : $blog;
    my $plugin = MT->component('linkblog');
    return $plugin->get_config_value('linkblog', "blog:$blog_id")
        ? 1 : 0;
}

sub save_link_to_entry {
    my ($cb, $app, $obj, $original) = @_;

    return if !$obj->id;
    return if !Linkblog->blog_is_linkblog($obj->blog_id);

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
    my ($cb, $app, $param, $tmpl) = @_;

    return if !Linkblog->blog_is_linkblog($param->{blog_id});

    my $plugin = MT->component('linkblog');
    Linkblog->add_url_field($plugin, @_);
    Linkblog->add_entry_url($plugin, @_);
    Linkblog->fill_fields_from_bookmarklet($plugin, @_);

    return;
}

sub fill_fields_from_bookmarklet {
    my $class = shift;
    my ($plugin, $cb, $app, $param, $tmpl) = @_;

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
    my $class = shift;
    my ($plugin, $cb, $app, $param, $tmpl) = @_;

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
    my $class = shift;
    my ($plugin, $cb, $app, $param, $tmpl) = @_;

    my $tags = $tmpl->getElementById('tags')
        or die "No metad? wah\n";

    my $urlset = $tmpl->createElement('setvarblock');
    $urlset->setAttribute('name', 'url-app-setting');
    $urlset->innerHTML(<<'EOF');
        <mtapp:setting
            id="url"
            label="<__trans phrase="Link">"
            label_class="top-label">
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
    my $plugin = MT->component('linkblog');
    my ($ctx, $args, $cond) = @_;

    my $entry = $ctx->stash('entry')
        or return '';

    require Linkblog::Link;
    my $link = Linkblog::Link->lookup($entry->id)
        or return '';

    return $link->url || '';
}

sub blog_if_linkblog {
    my ($ctx, $args) = @_;
    my $blog = $ctx->stash('blog')
        or return $ctx->_no_blog_error($args);
    return Linkblog->blog_is_linkblog($blog) ? 1 : 0;
}

1;

