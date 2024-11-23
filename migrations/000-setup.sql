-- Create text/html domain if not exists
create domain "text/html" as text;

-- HTML sanitization helper
create or replace function public.sanitize_html(text) returns text as $$
  select replace(replace(replace(replace(replace($1,
    '&', '&amp;'),
    '"', '&quot;'),
    '>', '>'),
    '<', '<'),
    '''', '&apos;')
$$ language sql;
