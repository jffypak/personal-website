module Jekyll
  class FuturePublishFilter < Generator
    safe true
    priority :high

    def generate(site)
      today = Date.today

      site.collections.each do |_name, collection|
        collection.docs.reject! do |doc|
          publish_date = doc.data['publish_date']
          if publish_date
            date = publish_date.is_a?(Date) ? publish_date : Date.parse(publish_date.to_s)
            date > today
          else
            true
          end
        end
      end
    end
  end
end
