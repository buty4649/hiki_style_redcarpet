#= parser.rb
#Authors::	buty <buty4649@gmail.com>
#license::	GNU Public License v2.0
#

require 'stringio'
require 'strscan'
require 'rubygems'
require 'redcarpet'

class HikiHTMLRender < Redcarpet::Render::HTML
  class Error < StandardError
  end

  class UnexpectedError < Error
  end

  def initialize( top_level = 2, extensions = {}  )
      @top_level = top_level - 1
      @use_wiki_name = extensions[:use_wiki_name] || true
      super(extensions)
  end

  def header(text, header_level)
      level = header_level + @top_level
      "<h#{level}>#{text}</h#{level}>"
  end

  def paragraph(text)
#      s = @use_wiki_name ? text.gsub(/\b(?:[A-Z]+[a-z\d]+){2,}\b/, %Q|<a href="\\1">\\1</a>|) : text
#      s = s.gsub(/\[\[([^\]]+?)\]\]/, %Q|<a href="\\1">\\1</a>|)
#     %Q|<p>#{s}</p>|
     %Q|<p>#{text}</p>|
  end

  def preprocess(full_document)
      escape_plugin_blocks(full_document)
  end

  def postprocess(full_document)
      full_document.gsub(/^<!-- \0(\d+)\0 -->$/) {
         %Q(<div class="plugin">{{#{escape_html(plugin_block($1.to_i))}}}</div>)
      }.gsub(/&lt;!-- \0(\d+)\0 --&gt;/) {
         %Q(<span class="plugin">{{#{escape_html(plugin_block($1.to_i))}}}</span>)
      }
  end

  def valid_plugin_syntax?(code)
    /['"]/ !~ code.gsub(/\\\\/, "").gsub(/\\['"]/,"").gsub(/'[^']*'|"[^"]*"/m, "")
  end

  def escape_plugin_blocks(text)
    s = StringScanner.new(text)
    buf = ""
    @plugin_blocks = []
    while chunk = s.scan_until(/\{\{/)
      tail = chunk[-2, 2]
      chunk[-2, 2] = ""
      buf << chunk
      # plugin
      if block = extract_plugin_block(s)
        @plugin_blocks.push block
        buf << "<!-- \0#{@plugin_blocks.size - 1}\0 -->"
      else
        buf << "{{"
      end
    end
    buf << s.rest
  end

  def extract_plugin_block(s)
    pos = s.pos
    buf = ""
    while chunk = s.scan_until(/\}\}/)
      buf << chunk
      buf.chomp!("}}")
      if valid_plugin_syntax?(buf)
        return buf
      end
      buf << "}}"
    end
    s.pos = pos
    nil
  end

  def plugin_block(id)
    @plugin_blocks[id] or raise UnexpectedError, "must not happen: #{id.inspect}"
  end

  def escape_html(text)
    text.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
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
      render = HikiHTMLRender.new(top_level, :use_wiki_name => @use_wiki_name)
      markdown = Redcarpet::Markdown.new(render,:autolink => false, :space_after_headers => true,:fenced_code_blocks => true, :tables => true, :strikethrough => true, :superscript => true)
      markdown.render(s)
    end
  end
end
