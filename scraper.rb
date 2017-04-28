#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class MembersPage < Scraped::HTML
  field :member_urls do
    noko.css('div#primary a[href*="/member/"]/@href').map(&:text)
  end
end

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

start = 'http://www.barbadosparliament.com/member/listall'
data = scrape(start => MembersPage).member_urls.map do |url|
  scrape(url => MemberPage).to_h
end
# puts data

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i(id term), data)
