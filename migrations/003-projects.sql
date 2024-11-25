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
    <article class="project-item fade-in">
    <div class="project-header" style="background-image: url('%6$s')">
      <h2>%2$s</h2>
    </div>
      <div class="project-content">
        %3$s
      </div>
      <a href="%5$s" target="_blank">Check it out</a>
      <small>Posted: %4$s</small>
    </article>
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

-- Function to get all type work projects as HTML
create or replace function public.get_work_projects() returns "text/html" as $$
  select coalesce(
    string_agg(public.html_project(p), '' order by p.created_at desc),
    '<div class="no-projects"><p>No work projects available.</p></div>'
  ) from projects p where p.type = 'work';
$$ language sql;

-- Function to get all type personal projects as HTML
create or replace function public.get_personal_projects() returns "text/html" as $$
  select coalesce(
    string_agg(public.html_project(p), '' order by p.created_at desc),
    '<div class="no-projects"><p>No personal projects available.</p></div>'
  ) from projects p where p.type = 'personal';
$$ language sql;
