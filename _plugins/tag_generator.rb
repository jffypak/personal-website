module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      today = Date.today
      tags = site.documents.select { |doc|
        pd = doc.data['publish_date']
        pd.nil? || (pd.is_a?(Date) ? pd : Date.parse(pd.to_s)) <= today
      }.flat_map { |post| post.data['tags'] || [] }.to_set
      tags.each do |tag|
        site.pages << TagPage.new(site, site.source, tag)
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, tag)
      @site = site
      @base = base
      @dir  = File.join('tag', tag)
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['title'] = "Businesses tagged '#{tag}'"
    end
  end
end
