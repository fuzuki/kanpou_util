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
      /^(http:\/\/kanpou.+\/)(\d+)([hgcmt])(\d+)(\d\d\d\d)\.html/.match(l_url){|m|
        @date = m[2]
        @type = m[3]
        @volume = m[4].to_i
        @burl = m[1] + "button/" + m[2] + m[3] + m[4] + m[5] + "b.html"
      }
    end

    #
    def getMaxPage
      maxpage = 0
      if @type != "m"
        begin
          open(@burl) do |button|
            button.each do |bline|
              ubline = bline.encode("UTF-8","SHIFT_JIS")
              if /前ページ/.match(ubline)
                 /<[aA] (href|HREF)="\.\.\/\d+[hgct]\d+(\d\d\d\d)f\.html/.match(ubline){|m|
                   maxpage = m[2].to_i
                 }
              end
            end
          end
        rescue OpenURI::HTTPError => e
          #何もしない
        end
      end
      maxpage
    end

    # 記事一覧を取得
    def getArticles
      alist = []
      baseurl = /(http:.+\/)\d+[hgctm]\d+\.html/.match(@url)[1]
      pdfbase = /http:.+\/(\d+[hgctm]\d+)\d\d\d\d\.html/.match(@url)[1]
      if @type == "m"
        /\/(\d+m\d+)f\.html/.match(@url){|m|
          murl = baseurl + "pdf/" +m[1] + ".pdf"
          a = Article.new("目録",murl, 0)

          alist << a
        }
      else
        title = ""
        case @type
        when "h"
          title = "【本紙"
        when "g"
          title = "【号外"
        when "c"
          title = "【政府調達"
        when "t"
          title = "【特別号外"
        end
        title += "　第#{@volume}号】"
        getMaxPage.times do |page|
          pdfurl = baseurl + "pdf/" + pdfbase + ("%04d" % (page+1)) + ".pdf"
          a = Article.new(title,pdfurl, page+1)
          alist[page] = a
        end

        begin
          prepage = 0
          pretitle = ""
          open(@url) do |kanpo|
              kanpo.each do |kanpoline|
                ukanpoline = kanpoline.encode("UTF-8","SHIFT_JIS")
                /<[aA] (href|HREF)="\.\/(\d+[hgct]\d+)(\d\d\d\d)f\.html/.match(ukanpoline){|klm|
                  title = rm_tag(/<P>(.+)　………/.match(ukanpoline)[1])
                  page = klm[3].to_i
                  if (page - prepage) > 1
                    Range.new(prepage + 1,page,true).each do |bpage|
                      alist[bpage - 1].title += pretitle + ","
                    end
                  end
                  alist[page - 1].title += title + ","
                  prepage = page
                  pretitle = title
                }
              end
          end
          if prepage < alist.size
            Range.new(prepage + 1,alist.size).each do |bpage|
              alist[bpage - 1].title += pretitle + ","
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
    attr_accessor :title, :pdf, :page
    def initialize(l_title,l_url,l_page)
      @title = l_title
      @pdf = l_url
      @page = l_page
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
