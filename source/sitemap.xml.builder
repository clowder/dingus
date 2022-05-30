xml.instruct!
xml.urlset 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  site_url = "https://dingus.clowder.name/"
  blog.articles.each do |article|
    xml.url do
      xml.loc URI.join(site_url, article.url)
      xml.lastmod File.mtime(article.source_file).iso8601
      xml.changefreq 'weekly'
      xml.priority '0.5'
    end
  end
end
