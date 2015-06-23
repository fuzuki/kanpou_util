#!/usr/bin/ruby1.9.3
# coding: utf-8

Encoding.default_external = "UTF-8"

require 'json'
require "cgi"
require 'sqlite3'

# ==============================================
#  保存済み官報pdf一覧取得・検索
#    2015.6 by fuzuki
# ==============================================

cgi = CGI.new
print "Content-type: application/json\n\n"

month = cgi["month"].gsub(/-/,"").gsub(/'/,"''")
word = cgi["word"].gsub(/'/,"''")

db = SQLite3::Database.new(File.dirname(__FILE__) + "/kanpoulist.db")
sql = "select * from kanpoulist where pdf like '#{month}%' and title like '%#{word}%' order by pdf desc;"
print JSON.fast_generate(db.execute(sql))
