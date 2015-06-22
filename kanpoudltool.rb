#!/usr/bin/ruby1.9.3
# coding: utf-8 

Encoding.default_external = "UTF-8"

require 'open-uri'
require_relative 'kanpou'

# ==============================================
#  官報pdfダウンロードツール
#    2015.6 by fuzuki
#
#  PDF保存先のディレクトリを指定して、官報PDFをダウンロードします
#  ./kanpoudltool.rb <pdf save directory>
# ==============================================

dir = ARGV[0]
if !dir
  puts "no target dir."
  exit()
end

if !Dir.exist?(dir)
  Dir.mkdir(dir)
end

l = Kanpou.get()
l.each{|k|
  sleep(1) #連続アクセス回避
  k.getArticles.each{|a|
    filename = /\/(\d+[a-z]\d+\.pdf)/.match(a.pdf)[1]
    pdffile = File.dirname(__FILE__) + "/#{dir}/#{filename}"
    escaped = a.title.gsub(/'/,"''")
    #ファイル未取得ならダウンロード
    if !File.exist?(pdffile)
      sleep(1) # 連続アクセス回避
      open(a.pdf, 'rb') do |p|
        open(pdffile,'wb') do |savedfile|
          puts a.pdf
          savedfile.write(p.read)
        end
      end
    end
  }
}

