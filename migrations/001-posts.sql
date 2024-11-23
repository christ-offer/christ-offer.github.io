-- Create posts table
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.posts enable row level security;

-- Add RLS policy
create policy "Posts can be read by anyone"
  on posts for select
  using (true);

-- Individual post HTML formatter
create or replace function public.html_post(public.posts) returns text as $$
  select format($html$
    <div class="post" id="post-%1$s">
      <article>
        <h2>%2$s</h2>
        <div class="body">
          %3$s
        </div>
        <small>Posted: %4$s</small>
      </article>
    </div>
    $html$,
    $1.id,
    public.sanitize_html($1.title),
    public.sanitize_html($1.body),
    to_char($1.created_at, 'Month DD, YYYY')
  );
$$ language sql stable;

-- Function to get all posts as HTML (deprecated)
-- create or replace function public.get_posts() returns "text/html" as $$
--   select coalesce(
--     string_agg(public.html_post(p), '' order by p.created_at desc),
--     '<div class="no-posts"><p>No posts available.</p></div>'
--   )
--   from public.posts p;
-- $$ language sql;


-- Function to get posts with HTMX-specific pagination
create or replace function public.get_posts_htmx(
  page_number integer default 1,
  posts_per_page integer default 5
) returns "text/html" as $$
declare
  total_posts integer;
  total_pages integer;
begin
  -- Get total number of posts
  select count(*) into total_posts from public.posts;

  -- Calculate total pages
  total_pages := ceil(total_posts::float / posts_per_page);

  return (
    select
      case
        when total_posts = 0 then
          '<div class="no-posts"><p>No posts available.</p></div>'
        else
          concat(
            -- Posts content
            (
              select coalesce(
                string_agg(public.html_post(p), '' order by p.created_at desc),
                '<div class="no-posts"><p>No posts found for this page.</p></div>'
              )
              from (
                select *
                from public.posts
                order by created_at desc
                limit posts_per_page
                offset ((page_number - 1) * posts_per_page)
              ) p
            ),
            -- HTMX-specific pagination controls
            '<div class="pagination">',
            case when page_number > 1 then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_posts_htmx?page_number=%s" hx-target=".posts" class="prev-page">&laquo; Previous</button>',
                page_number - 1
              )
            else '' end,
            case when page_number < total_pages then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_posts_htmx?page_number=%s" hx-target=".posts" class="next-page">Next &raquo;</button>',
                page_number + 1
              )
            else '' end,
            format(
              '<span class="page-info">Page %s of %s</span>',
              page_number,
              total_pages
            ),
            '</div>'
          )
      end
  );
end;
$$ language plpgsql;