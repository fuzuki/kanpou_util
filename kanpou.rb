# encoding: utf-8

require 'open-uri'

# ==============================================
#  官報pdf utility
#   2015.6 by fuzuki
#
#  web版官報PDFを扱うための簡易ライブラリ
# ==============================================

module Kanpou
  INIT_URL = "http://kanpou.npb.go.jp/html/contents.html"
  BASE_URL = "http://kanpou.npb.go.jp/"

  # 官報クラス
  # date:日付(yyyymmdd)
  # type:アルファベット1文字(h-本紙,g-号外,c-調達,m-目録,t-特別号外)
  # volume:巻数
  class Kanpou
    attr_reader :date, :type, :volume
    def initialize(l_url)
      @url = l_url
      /\/(\d+)([hgcmt])(\d+)\//.match(l_url){|m|
        @date = m[1]
        @type = m[2]
        @volume = m[3].to_i
      }
    end

    # 記事一覧を取得
    def getArticles
      alist = []
      baseurl = /(http:.+\/)\d+[hgctm]\d+.html/.match(@url)[1]
      if @type == "m"
        /\/(\d+m\d+)f\.html/.match(@url){|m|
          murl = baseurl + "pdf/" +m[1] + ".pdf"
          a = Article.new("目録",murl)

          alist << a
        }
      else
            begin
            open(@url) do |kanpo|
              kanpo.each do |kanpoline|
                ukanpoline = kanpoline.encode("UTF-8","SHIFT_JIS")
                /<[aA] (href|HREF)="\.\/(\d+[hgct]\d+)f\.html/.match(ukanpoline){|klm|
                  aurl = baseurl + "pdf/" +klm[2] + ".pdf"
                  title = rm_tag(/<P>(.+)　………/.match(ukanpoline)[1])
                  a = Article.new(title,aurl)
                  alist << a
                }
              end
            end
            rescue OpenURI::HTTPError => e
              # 何もしない
            end

      end
      alist
    end

    private
    # htmlタグ除去
    def rm_tag(str)
      l_str = str.dup
      l_str.sub!(/<[^<>]*>/,"") while /<[^<>]*>/ =~ l_str
      l_str
    end
  end

  # 記事クラス
  # title: 記事タイトル
  # pdf: WEB官報PDFのurl
  class Article
    attr_reader :title, :pdf
    def initialize(l_title,l_url)
      @title = l_title
      @pdf = l_url
    end
  end

  # 官報一覧を取得
  def self.get
    klist = []
    begin
    open(INIT_URL)do |contents|
      contents.each do |listline|
        ulistline = listline.encode("UTF-8","SHIFT_JIS")
          /<a href="\.\.\/(\d+.+)f\.html.+>(.+)<\/a>/.match(ulistline){|listm|
            kurl = BASE_URL + listm[1] + ".html"
            k = Kanpou.new(kurl)
            klist << k
          }
      end
    end #open(INIT_URL)
    rescue OpenURI::HTTPError => e
      # 何もしない
    end
    klist
  end
end
