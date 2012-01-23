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

  WIKI_LINK_RE = /\[\[.+?\]\]/
  WIKI_NAME_RE = /\b(?:[A-Z]+[a-z\d]+){2,}\b/
  def paragraph(txt)
      re = /(#{WIKI_LINK_RE})|(#{WIKI_NAME_RE})/xo
      buf = ""
      str = txt
      while m = re.match(str)
      	buf << m.pre_match
	str = m.post_match

	wiki_link, wiki_name = m[1,2]
	if wiki_link
	   buf << compile_wiki_link(wiki_link[2...-2])
	elsif wiki_name
	   buf << %Q|<a href="#{wiki_name}">#{wiki_name}</a>|
	end
      end
      buf << str
      %Q|<p>#{buf}</p>\n|
  end

  def compile_wiki_link(link)
     if m = /\A(?>[^|\\]+|\\.)*\|/.match(link)
       %Q|<a href="#{m.post_match}">#{m[0].chop}</a>|
     else
       %Q|<a href="#{link}">#{link}</a>|
     end
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
      markdown = Redcarpet::Markdown.new(render,:autolink => false, :space_after_headers => true,:fenced_code_blocks => true, :tables => true, :strikethrough => true, :superscript => true)
      markdown.render(s)
    end
  end
end
