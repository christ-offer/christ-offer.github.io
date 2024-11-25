-- Create posts table
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null,
  summary text not null,
  body text not null,
  post_url text,
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.posts enable row level security;

-- Add RLS policy
create policy "Posts can be read by anyone"
  on posts for select
  using (true);

-- Create a trigger to create a post_url from the title
create or replace function public.create_post_url() returns trigger as $$
begin
  new.post_url := public.sanitize_input(new.title);
  return new;
end;
$$ language plpgsql;

create trigger create_post_url
  before insert or update on public.posts
  for each row
  execute procedure public.create_post_url();

create trigger update_post_url
  before update on public.posts
  for each row
  execute procedure public.create_post_url();


-- Individual post HTML formatter
create or replace function public.html_post(public.posts) returns text as $$
  select format($html$
    <div class="fade-in post" id="post-%1$s">
      <article>
        <h2>%2$s</h2>
        <div class="body">
          <p>
            %3$s
          </p>
        </div>
        <small>Posted: %5$s</small>
      </article>
    </div>
    $html$,
    $1.id,
    public.sanitize_html($1.title),
    $1.body,
    public.sanitize_html($1.post_url),
    to_char($1.created_at, 'Month DD, YYYY')
  );
$$ language sql stable;


-- Individual post card HTML formatter (should only have title, summary and post_url for a link)
create or replace function public.html_post_card(public.posts) returns text as $$
  select format($html$
    <div class="post-card fade-in" id="post-%1$s">
      <article>
        <h2>%2$s</h2>
        <div class="body">
          <p>
            %3$s
          </p>
        </div>
        <a href="post.html?title=%4$s">Read more</a>
        <small>Posted: %5$s</small>
      </article>
    </div>
    $html$,
    $1.id,
    public.sanitize_html($1.title),
    public.sanitize_html($1.summary),
    public.sanitize_html($1.post_url),
    to_char($1.created_at, 'Month DD, YYYY')
  );
$$ language sql stable;

-- Function to get latest post from the database
create or replace function public.get_latest_post() returns "text/html" as $$
declare
  post public.posts;
begin
  select * into post from public.posts order by created_at desc limit 1;
  if post is null then
    return '<div class="no-posts">No posts</div>';
  end if;
  return public.html_post_card(post);
end;
$$ language plpgsql;

--Functin to get a single post based on title
create or replace function public.get_post_by_title(input_title text) returns "text/html" as $$
declare
  post public.posts;
  sanitized_input text;
begin
  -- Sanitize the input title
  sanitized_input := public.sanitize_input(input_title);

  -- If sanitized title is empty or null, return no posts
  if sanitized_input is null or sanitized_input = '' then
    return '<div class="no-posts">No posts</div>';
  end if;

  select * into post from public.posts where post_url = sanitized_input;

  if post is null then
    return '<div class="no-posts">No posts</div>';
  end if;

  return public.html_post(post);
end;
$$ language plpgsql;

-- Function get post card based on title
create or replace function public.get_post_card_by_title(input_title text) returns "text/html" as $$
declare
  post public.posts;
  sanitized_input text;
begin
  -- Sanitize the input title
  sanitized_input := public.sanitize_input(input_title);

  -- If sanitized title is empty or null, return no posts
  if sanitized_input is null or sanitized_input = '' then
    return '<div class="no-posts">No posts</div>';
  end if;

  select * into post from public.posts where post_url = sanitized_input;

  if post is null then
    return '<div class="no-posts">No posts</div>';
  end if;

  return public.html_post_card(post);
end;
$$ language plpgsql;

-- Function to get posts based on search query (if no query - returns all posts)
create or replace function public.search_posts(
  search_query text default '',
  page_number integer default 1,
  posts_per_page integer default 5
) returns "text/html" as $$
declare
  search_query_sanitized text;
  total_matching_posts integer;
  total_pages integer;
  search_query_param text;
begin
  -- Sanitize the search query
  search_query_sanitized := public.sanitize_input(search_query);

  -- Prepare search query parameter for URLs
  search_query_param := case
    when search_query_sanitized is not null and search_query_sanitized != ''
    then '&search_query=' || search_query_sanitized
    else ''
  end;

  -- Get total matching posts
  select count(*) into total_matching_posts
  from public.posts
  where search_query_sanitized is null
    or search_query_sanitized = ''
    or title ilike '%' || search_query_sanitized || '%';

  -- Calculate total pages
  total_pages := ceil(total_matching_posts::float / posts_per_page);

  return (
    select
      case
        when total_matching_posts = 0 then
          '<div class="no-posts">No posts found matching your search.</div>'
        else
          concat(
            -- Posts content
            (
              select coalesce(
                string_agg(public.html_post_card(p), '' order by p.created_at desc),
                '<div class="no-posts">No posts found on this page.</div>'
              )
              from (
                select *
                from public.posts
                where search_query_sanitized is null
                  or search_query_sanitized = ''
                  or title ilike '%' || search_query_sanitized || '%'
                order by created_at desc
                limit posts_per_page
                offset ((page_number - 1) * posts_per_page)
              ) p
            ),
            -- Pagination controls
            '<div class="pagination">',
            case when page_number > 1 then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/search_posts?page_number=%s%s" hx-target=".posts" class="prev-page">&laquo; Previous</button>',
                page_number - 1,
                search_query_param
              )
            else '' end,
            case when page_number < total_pages then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/search_posts?page_number=%s%s" hx-target=".posts" class="next-page">Next &raquo;</button>',
                page_number + 1,
                search_query_param
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
