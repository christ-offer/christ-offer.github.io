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

create or replace function public.sanitize_input(input text) returns text as $$
begin
  return regexp_replace(
    regexp_replace(
      regexp_replace(input, '\s+', '-', 'g'),  -- Convert spaces to hyphens
      '[^a-zA-Z0-9\-:]', '', 'g'               -- Remove other non-alphanumeric characters except hyphens and colons
    ),
    '\-+', '-', 'g'                            -- Replace multiple consecutive hyphens with single hyphen
  );
end;
$$ language plpgsql;
