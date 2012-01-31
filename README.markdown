hiki_style_redcarpet
=======================================

これは、[Hiki](http://hikiwiki.org/ja/)で[Redcarpet](https://github.com/tanoku/redcarpet)を使用するためのモジュールです。


動作確認環境
---------------------------------------
* Ruby v1.8.7
* Hiki 0.9dev
* Redcarpet v2.0.1

※  本モジュールはUTF-8で記述されているため、Hiki 0.9dev以前のEUC環境ではうまく動作しない可能性があります


インストール方法
----------------------------------------
* Redcarpetのインストール
	1. gem install redcarpet

* hiki_style_redcarpetのインストール
	1. hiki_style_redcarpet/redcarpet を、HikiRoot/style へコピーする
	2. hikiconf.rb の@style変数をredcarpet に変更する
		<code>
		編集前:
		#@style = 'default'
		
		編集後:
		@style = 'redcarpet'	
		</code>

同梱のTextFormattingRules を同名のWikiページに貼り付けて保存すると編集ページから参照できて便利です。


ライセンス
----------------------------------------
Hikiに同梱されているモジュールのコードを一部利用しているため、Hikiと同じGNU GPL2でライセンスします。
