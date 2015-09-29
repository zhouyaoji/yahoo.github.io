module Jekyll
  class Display < Liquid::Tag 
    @@not_capitalized = ["or","and","the","a","an","for","to","at","by","nor"]
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end
    def render(content)
      c = @text.split("_")
      str = ""
      c.each do |w|
        if @@not_capitalized.include? w
          str += w + " "
        else
          str += w.capitalize + " "
        end
      end
      @text = str
    end
  end
end
Liquid::Template.register_tag('display_heading', Jekyll::Display)

