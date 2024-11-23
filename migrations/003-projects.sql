-- Create projects table
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  url text,
  photo_url text,
  type text, -- work / personal
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.projects enable row level security;

-- Add RLS policy
create policy "Projects can be read by anyone" on projects for select using (true);


-- Individual project HTML formatter
create or replace function public.html_project(public.projects) returns text as $$
  select format($html$
    <a href="%5$s" target="_blank">
      <article class="project-item">
        <h2>%2$s</h2>
        <img src="%6$s" />
        <div class="project-content">
          %3$s
        </div>
        <small>Posted: %4$s</small>
      </article>
    </a>
    $html$,
    $1.id,
    public.sanitize_html($1.title),
    public.sanitize_html($1.description),
    to_char($1.created_at, 'Month DD, YYYY'),
    coalesce($1.url, '#'),
    coalesce($1.photo_url, '#')
  );
$$ language sql stable;

-- Function to get all projects as HTML
create or replace function public.get_projects() returns "text/html" as $$
  select coalesce(
    string_agg(public.html_project(p), '' order by p.created_at desc),
    '<div class="no-projects"><p>No projects available.</p></div>'
  ) from projects p;
$$ language sql;
