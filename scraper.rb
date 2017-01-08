#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'date'
require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def date_from(str)
  return if str.to_s.empty?
  Date.parse(str)
end

def party_from(node)
  return ['Democratic Labour Party', 'DLP'] if node.text.include? 'www.dlpbarbados.org'
  return ['Barbados Labour Party', 'BLP'] if node.text.include? 'www.blp.org.bb'
  return ['Barbados Labour Party', 'BLP'] if node.text.include? 'voteblp.com'
  return ['Barbados Labour Party', 'BLP'] if node.css('img/@src').text.include? 'blp_logo.jpg'
  raise binding.pry
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('div#primary a[href*="/member/"]/@href').map(&:text).each do |link|
    scrape_member(link)
  end
end

def scrape_member(url)
  noko = noko_for(url)

  party, party_id = party_from(noko.xpath('.//h2[contains(.,"Party")]/following-sibling::p[1]'))

  data = {
    id:           url[/(\d+)$/, 1],
    name:         noko.css('h1.page-title').text.gsub(', M.P.','').tidy,
    image:        noko.css('div.entry-thumb img/@src').text,
    constituency: noko.css('.post-excerpt').text.tidy,
    party:        party,
    party_id:     party_id,
    role:         noko.xpath('.//h3[contains(.,"Designation")]/following-sibling::p').text.tidy,
    telephone:    noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text[/Telephone:\s*(.*?)\s*$/, 1].tidy,
    fax:          noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text[/Fax:\s*(.*?)\s*$/, 1].tidy,
    email:        noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text.lines.find { |l| l.include? '@' }.tidy,
    term:         '2013',
    source:       url,
  }
  # puts data
  ScraperWiki.save_sqlite(%i(id term), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.barbadosparliament.com/member/listall')
