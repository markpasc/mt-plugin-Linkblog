<?php
function smarty_function_MTLinkblogUrl($args, &$ctx) {
    $entry = $ctx->stash('entry') or return '';
    $url = $ctx->mt->db->get_var("
        SELECT links_url
        FROM   mt_links
        WHERE  links_id=" .
        $entry['entry_id']);
    return $url or '';
}
?>
