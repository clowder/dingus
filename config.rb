require "lib/grayscale"

set :markdown_engine, :redcarpet
set :markdown, {
  autolink: true,
  fenced_code_blocks: true,
  footnotes: true,
  link_attributes: {rel: "nofollow noopener"},
  prettify: true,
  smartypants: true,
  tables: true,
}

# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

activate :external_pipeline,
  name: :tailwind,
  command: build? ? 'yarn run build' : 'yarn run dev',
  source: "tmp/assets",
  latency: 1

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

activate :syntax

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

# Activate and configure blog extension

activate :blog do |blog|
  # This will add a prefix to all links, template references and source paths
  # blog.prefix = "blog"

  # blog.permalink = "{year}/{month}/{day}/{title}.html"
  # Matcher for blog source files
  # blog.sources = "{year}-{month}-{day}-{title}.html"
  # blog.taglink = "tags/{tag}.html"
  # blog.layout = "layout"
  # blog.summary_separator = /(READMORE)/
  # blog.summary_length = 250
  # blog.year_link = "{year}.html"
  # blog.month_link = "{year}/{month}.html"
  # blog.day_link = "{year}/{month}/{day}.html"
  # blog.default_extension = ".markdown"
  # blog.tag_template = "tag.html"
  # blog.calendar_template = "calendar.html"

  # Enable pagination
  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/{num}"
end

page "/feed.xml", layout: false
page "/sitemap.xml", layout: false

# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def title(text)
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(filter_html: true, no_images: true, no_links: true, no_styles: true))
    @markdown.render(text)
  end

  def last_modified_at(article)
    gittime = `git log -1 --pretty="format:%ci" #{article.source_file}`

    if gittime.present?
      Time.parse(gittime)
    else
      article.date.to_time
    end
  end
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

configure :build do
  config[:build_dir] = "./docs"
  activate :asset_hash
end
