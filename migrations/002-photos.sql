-- Create photos table
create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  photo_url text not null,
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.photos enable row level security;

-- Add RLS policy
create policy "Photos can be read by anyone" on photos for select using (true);

-- Individual photos HTML formatter
create or replace function public.html_photo(public.photos) returns text as $$
  select format($html$
    <article class="gallery-item" onclick="openModal(this)">
      <img src="%2$s" />
    </article>
    $html$,
    $1.id,
    $1.photo_url
  );
$$ language sql stable;

-- Function to get all photos as HTML
create or replace function public.get_photos() returns "text/html" as $$
  select coalesce(
   string_agg(public.html_photo(p), '' order by p.created_at desc),
   '<div class="no-photos"><p>No photos available.</p></div>'
  ) from photos p;
$$ language sql;

-- Function to get latest photo from the database
create or replace function public.get_latest_photo() returns "text/html" as $$
declare
  photo public.photos;
begin
  select * into photo from public.photos order by created_at desc limit 1;
  if photo is null then
    return '<div class="no-photos">No photos</div>';
  end if;
  return public.html_photo(photo);
end;
$$ language plpgsql;

-- Function to get photos with HTMX-specific pagination
create or replace function public.get_photos_htmx(
  page_number integer default 1,
  photos_per_page integer default 8
) returns "text/html" as $$
declare
  total_photos integer;
  total_pages integer;
begin
  -- Get total number of photos
  select count(*) into total_photos from public.photos;

  -- Calculate total pages
  total_pages := ceil(total_photos::float / photos_per_page);

  return (
    select
      case
        when total_photos = 0 then
          '<div class="no-photos"><p>No photos available.</p></div>'
        else
          concat(
            -- Photo content
            (
              select coalesce(
                string_agg(public.html_photo(p), '' order by p.created_at desc),
                '<div class="no-photos"><p>No photos found for this page.</p></div>'
              )
              from (
                select *
                from public.photos
                order by created_at desc
                limit photos_per_page
                offset ((page_number - 1) * photos_per_page)
              ) p
            ),
            -- HTMX-specific pagination controls
            '<div class="pagination">',
            case when page_number > 1 then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_photos_htmx?page_number=%s" hx-target=".gallery" class="prev-page">&laquo; Previous</button>',
                page_number - 1
              )
            else '' end,
            case when page_number < total_pages then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_photos_htmx?page_number=%s" hx-target=".gallery" class="next-page">Next &raquo;</button>',
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
