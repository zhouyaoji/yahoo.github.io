module Jekyll
  module LastUpdate
    def file_date(input)
      File.mtime(input)
    end
  end
end
Liquid::Template.register_filter(Jekyll::LastUpdate)
