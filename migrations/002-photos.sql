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
