#!/usr/bin/ruby1.9.3
# coding: utf-8 

Encoding.default_external = "UTF-8"

require 'open-uri'
require 'sqlite3'
require_relative 'kanpou'

# ==============================================
#  官報pdfダウンロードツール
#    2015.6 by fuzuki
#
#  官報PDFをダウンロードします
#  cronで毎日または毎週実行することを想定しています。
# ==============================================

l = Kanpou.get()
db = SQLite3::Database.new(File.dirname(__FILE__) + "/kanpoulist.db")

l.each{|k|
  sleep(1)
  k.getArticles.each{|a|
    filename = /\/(\d+[a-z]\d+\.pdf)/.match(a.pdf)[1]
    pdffile = File.dirname(__FILE__) + "/kanpou/" + filename
    escaped = a.title.gsub(/'/,"''")
    #db登録済みかどうか確認
    sql = "select count(*) from kanpoulist where pdf='#{filename}' and title='#{escaped}';"
    if db.execute(sql)[0][0] == 0
      sql_str = "insert into kanpoulist(pdf,title) values('#{filename}','#{escaped}');"
      db.execute(sql_str)
    end
    #ファイル未取得ならダウンロード
    if !File.exist?(pdffile)
      sleep(1)
      open(a.pdf, 'rb') do |p|
        open(pdffile,'wb') do |savedfile|
          savedfile.write(p.read)
        end
      end
    end
  }
}

db.close
