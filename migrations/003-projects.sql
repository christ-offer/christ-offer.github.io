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
create or replace function public.html_work_project(public.projects) returns text as $$
  select format($html$
    <article class="project-item fade-in work-project">
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

-- Individual project HTML formatter for personal projects
create or replace function public.html_personal_project(public.projects) returns text as $$
  select format($html$
    <article class="project-item fade-in personal-project">
    <div class="project-header">
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
    coalesce($1.url, '#')
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


-- Function to get projects with HTMX-specific pagination
create or replace function public.get_projects_htmx(
  page_number integer default 1,
  projects_per_page integer default 2
) returns "text/html" as $$
declare
  total_projects integer;
  total_pages integer;
begin
  -- Get total number of projects
  select count(*) into total_projects from public.projects;

  -- Calculate total pages
  total_pages := ceil(total_projects::float / projects_per_page);

  return (
    select
      case
        when total_projects = 0 then
          '<div class="no-projects"><p>No projects available.</p></div>'
        else
          concat(
            -- Project content
            (
              select coalesce(
                string_agg(
                  case
                    when p.type = 'work' then public.html_work_project(p)
                    else public.html_personal_project(p)
                  end,
                '' order by p.created_at desc),
                '<div class="no-projects"><p>No projects found for this page.</p></div>'
              )
              from (
                select *
                from public.projects
                order by created_at desc
                limit projects_per_page
                offset ((page_number - 1) * projects_per_page)
              ) p
            ),
            -- HTMX-specific pagination controls
            '<div class="pagination" id="pagination" hx-swap-oob="true">',
            case when page_number > 1 then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_projects_htmx?page_number=%s" hx-target=".projects" class="prev-page">&laquo; Previous</button>',
                page_number - 1
              )
            else '' end,
            case when page_number < total_pages then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_projects_htmx?page_number=%s" hx-target=".projects" class="next-page">Next &raquo;</button>',
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
