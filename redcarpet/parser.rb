#= parser.rb
#Authors::	buty <buty4649@gmail.com>
#license::	GNU Public License v2.0
#

require 'rubygems'
require 'redcarpet'

class HikiHTMLRender < Redcarpet::Render::HTML
  def initialize( top_level = 2, extensions = {}  )
      @top_level = top_level - 1
      super(extensions)
  end

  def header(text, header_level)
      level = header_level + @top_level
      "<h#{level}>#{text}</h#{level}>"
  end
end

module Hiki
  class Parser_redcarpet

    class << self
      def heading( str, level = 1 )
        if level == 1 then
		str + "\n" + "=" * (str.length < 4 ? 4 : str.length)
	elsif level == 2 then
		str + "\n" + "-" * (str.length < 4 ? 4 : str.length)
	else
		"#" * level + " #{str}"
	end
      end

      def link( link_str, str = nil )
      	(str ? "[#{str}]" : "") + "(#{link_str})"
      end

      def blockquote( str )
        str.split(/\n/).collect{|s| %Q|    #{s}\n|}.join
      end
    end
    
    def initialize( conf )
      @use_wiki_name = conf.use_wikiname
    end

    def parse( s, top_level = 2 )
      render = HikiHTMLRender.new(top_level)
      markdown = Redcarpet::Markdown.new(render,:autolink => true, :space_after_headers => true,:fenced_code_blocks => true, :tables => true, :strikethrough => true, :superscript => true)
      markdown.render(s)
    end
  end
end
