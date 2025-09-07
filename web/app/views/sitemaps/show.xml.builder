xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @static_paths.each do |path|
    xml.url do
      xml.loc File.join(@canonical, path)
      xml.changefreq "weekly"
      xml.priority "0.6"
    end
  end

  @recruiters.each do |r|
    xml.url do
      xml.loc File.join(@canonical, "/recruiters/#{r.public_slug}")
      xml.changefreq "weekly"
      xml.priority "0.7"
      xml.lastmod r.updated_at&.utc&.iso8601
    end
  end
end

