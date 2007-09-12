<?php
function smarty_function_mtlinkblogurl($args, &$ctx) {
    $entry = $ctx->stash('entry');
    if (!$entry) return '';
    $url = $ctx->mt->db->get_var("
        SELECT links_url
        FROM   mt_links
        WHERE  links_id=" .
        $entry['entry_id']);
    if (!$url) return '';
    return $url;
}
?>
