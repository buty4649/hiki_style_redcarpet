#= parser.rb
#Authors::  buty <buty4649@gmail.com>
#license::  GNU Public License v2.0
#

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
		super(extensions.merge(:filter_html => true))
	end

	def block_code(code, language)
		attr = language && %Q| class="#{language}"|
		c = code.gsub(/<!-- \0(\d+)\0 -->/) {
			"{{" + plugin_block($1.to_i) + "}}"
		}
		%Q|<pre><code#{attr}>#{escape_html(c)}</code></pre>\n|
	end

	def header(text, header_level)
		level = header_level + @top_level
		%Q|<h#{level}>#{parse_wiki_name(text)}</h#{level}>\n|
	end

	def list_item(text, list_type)
		%Q|<li>#{parse_wiki_name(text)}</li>\n|
	end

	def table_cell(content, alignment)
		attr = alignment && %Q| align="#{alignment}"|
		%Q|<td#{attr}>#{parse_wiki_name(content)}</td>\n|
	end

	def paragraph(text)
		%Q|<p>#{parse_wiki_name(text)}</p>\n|
	end

	def preprocess(full_document)
		buf = full_document.gsub(%r|^//.*|, "")
		escape_plugin_blocks(buf)
	end

	def postprocess(full_document)
		full_document.gsub(/^<!-- \0(\d+)\0 -->$/) {
			%Q|<div class="plugin">{{#{escape_html(plugin_block($1.to_i))}}}</div>|
		}.gsub(/&lt;!-- \0(\d+)\0 --&gt;/) {
			%Q|<span class="plugin">{{#{escape_html(plugin_block($1.to_i))}}}</span>|
		}
	end

	private

	HTML_RE = /<[^'">]+(?:\s|"[^"]*"|'[^']*'|)*>[^<]+?<\/[^>]+?>/
	WIKI_LINK_RE = /\[\[.+?\]\]/
	WIKI_NAME_RE = /\b(?:[A-Z]+[a-z\d]+){2,}\b/

	def parse_wiki_name(text)
		re = lambda {
			if @use_wiki_name
				/(#{HTML_RE})|(#{WIKI_LINK_RE})|(#{WIKI_NAME_RE})/xo
			else
				/(#{HTML_RE})|(#{WIKI_LINK_RE})/xo
			end
		}.call
		buf = ""
		str = text
		while m = re.match(str)
			buf << m.pre_match
			str = m.post_match

			wiki_link, wiki_name = m[2,3]
			if wiki_link
				buf << lambda {|link|
					if m = /\A(?>[^|\\]+|\\.)*\|/.match(link)
						%Q|<a href="#{m[0].chop}">#{m.post_match}</a>|
					else
						%Q|<a href="#{link}">#{link}</a>|
					end
				}.call(wiki_link[2...-2])
			elsif wiki_name
				buf << %Q|<a href="#{wiki_name}">#{wiki_name}</a>|
			else
				buf << m[0]
			end
		end
		buf << str
		buf.chomp
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
			Redcarpet::Markdown.new(render, :autolink	=> true,
						:space_after_headers	=> true,
						:fenced_code_blocks	=> true,
						:tables			=> true,
						:strikethrough		=> true,
						:superscript		=> true
					       ).render(s)
		end
	end
end
