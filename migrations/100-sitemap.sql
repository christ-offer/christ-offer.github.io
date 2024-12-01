CREATE OR REPLACE FUNCTION public.sitemap() RETURNS text AS $$
BEGIN
RETURN (
    '<?xml version="1.0" encoding="UTF-8"?>' ||
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' ||
    -- Home page
    '<url>' ||
    '<loc>https://christ-offer.github.io</loc>' ||
    '<lastmod>' || CURRENT_DATE::text || '</lastmod>' ||
    '<priority>1.0</priority>' ||
    '</url>' ||
    -- Projects page
    '<url>' ||
    '<loc>https://christ-offer.github.io/projects</loc>' ||
    '<lastmod>' || CURRENT_DATE::text || '</lastmod>' ||
    '<priority>0.8</priority>' ||
    '</url>' ||
    -- Posts
    COALESCE((
        SELECT string_agg(
            '<url>' ||
            '<loc>https://christ-offer.github.io/post/' || post_url || '</loc>' ||
            '<lastmod>' || created_at::date::text || '</lastmod>' ||
            '<priority>0.8</priority>' ||
            '</url>',
            ''
        )
        FROM posts
    ), '') ||
    '</urlset>'
);

EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Sitemap error: %', SQLERRM;
    RETURN '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>https://christ-offer.github.io</loc></url></urlset>';
END;
$$ LANGUAGE plpgsql;
