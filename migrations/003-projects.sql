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
      <a href="%5$s" target="_blank"><ion-icon name="globe-outline"></ion-icon></a>
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
    <div class="project-header" style="background-image: url('%6$s')">
      <h2>%2$s</h2>
    </div>
      <div class="project-content">
        %3$s
      </div>
      <a href="%5$s" target="_blank"><ion-icon name="logo-github"></ion-icon></a>
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


create or replace function public.get_projects_htmx(
  page_number integer default 1,
  projects_per_page integer default 2,
  project_type text default null  -- Add new parameter for filtering by type
) returns "text/html" as $$
declare
  total_projects integer;
  total_pages integer;
begin
  -- Get total number of projects (filtered by type if specified)
  select count(*) into total_projects
  from public.projects
  where (project_type is null or type = project_type); -- Add type filter

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
                where (project_type is null or type = project_type) -- Add type filter
                order by created_at desc
                limit projects_per_page
                offset ((page_number - 1) * projects_per_page)
              ) p
            ),
            -- HTMX-specific pagination controls
            '<div class="pagination" id="pagination" hx-swap-oob="true">',
            case when page_number > 1 then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_projects_htmx?page_number=%s&project_type=%s" hx-target=".projects" class="prev-page">&laquo; Previous</button>',
                page_number - 1,
                coalesce(project_type, '')
              )
            else '' end,
            case when page_number < total_pages then
              format(
                '<button hx-get="https://sudfrkwfniwvltkhocwg.supabase.co/rest/v1/rpc/get_projects_htmx?page_number=%s&project_type=%s" hx-target=".projects" class="next-page">Next &raquo;</button>',
                page_number + 1,
                coalesce(project_type, '')
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
