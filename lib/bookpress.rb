# require "bookpress/version"
require "bundler"
require "pathname"
require "nokogiri"
require "redcarpet"
require "pygments.rb"

# This reopens the Hash class to add a method to allow sorting by key recursively
class Hash
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

module Bookpress
  class Book
    attr_accessor :title, :pages, :tree, :stylesheets

    def initialize(directory)
      # Get all markdown files
      @pages = Pathname.glob("#{directory}/" "**/*.{md,markdown}")

      @stylesheets = []

      stylenames = Pathname.glob("#{directory}/" "**/*.{css}")
      stylenames.each do |sheet|
        file = File.new(sheet, "r")
        style = ""
        while (line = file.gets)
            style << line
        end
        file.close
        @stylesheets << style
      end

      # Create a Hash to store the book tree structure
      @tree = Hash.new { |h, k| h[k] = Hash.new &h.default_proc }

      @pages.each do |page|
       subdirectory = @tree
       page_name    = page.basename
       page.cleanpath.each_filename do |segment|
         subdirectory[segment]
         if segment.to_s == page_name.to_s
           subdirectory[segment] = Utility.markdown_renderer.render(page.read)
         end
         subdirectory = subdirectory[segment]
       end
      end

      # Sort the structure by key
      @tree = @tree.sort_by_key(true) { |x, y| Utility.orderify(x.to_s) <=> Utility.orderify(y.to_s) }
    end

    def to_html
      # Build the document
      builder = Nokogiri::HTML::Builder.new do |doc|
       doc.html do
        doc.head do
          @stylesheets.each do |sheet|
            doc.style "\n#{sheet}\n"
          end
        end
         doc.body do
           doc.cdata Utility.articlize(@tree)
         end
       end
      end

      builder.to_html
    end
  end

  class Utility
    def self.titleize(title)
      if title
        new_title        = title.sub(/(\d*_)/, '')
        really_new_title = new_title.sub(/(\.\w*)/, '')
        words            = really_new_title.to_s.split('_')
        words.each do |word|
          if word.length <3
            word.downcase!
          elsif word.length >3
            word.capitalize!
          end
        end
        words.join ' '
      else
        ''
      end
    end

    def self.idify(title)
      if title
        new_title           = title.sub(/(\d*_)/, '')
        really_new_title    = new_title.sub(/(\.\w*)/, '')
        extremely_new_title = really_new_title.sub(/ /, '_')
        extremely_new_title.downcase!
        extremely_new_title
      else
        ''
      end
    end

    def self.orderify(title)
      if title
        /(\d*)_/.match(title)[1]
      else
        ''
      end
    end

    def self.articlize(tree, parent = nil)
      unless tree.is_a?(String)
        article = ""
        tree.each do |key, value|
          html = ""
          if Utility.idify(key) == Utility.idify(parent)
            if value.is_a?(String)
              html << value
            else
              html << Utility.articlize(tree[key], key)
            end
          else
            html = "<article id='#{Utility.idify(key)}'>"
            html << ("<header><h1>#{Utility.titleize(key)}</h1></header>")
            if value.is_a?(String)
              html << value
            else
              html << Utility.articlize(tree[key], key)
            end
            html << "</article>"
          end
          article << html
        end
        article
      else
        tree
      end
    end

    def self.markdown_renderer
       Redcarpet::Markdown.new(Bookpress::HTMLRenderer, {
        autolink:                     true,
        disable_indented_code_blocks: true,
        fenced_code_blocks:           true,
        space_after_headers:          true
      })
    end
  end

  class HTMLRenderer < Redcarpet::Render::HTML
    include Redcarpet::Render::SmartyPants

    def block_code(code, language)
      result = Pygments.highlight(code, lexer: language)
      result
    end
  end
end
