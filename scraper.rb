#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'date'
require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  field :member_urls do
    noko.css('div#primary a[href*="/member/"]/@href').map(&:text)
  end
end

class MemberPage < Scraped::HTML
  field :id do
    url[/(\d+)$/, 1]
  end

  field :name do
    noko.css('h1.page-title').text.gsub(', M.P.','').tidy
  end

  field :image do
    noko.css('div.entry-thumb img/@src').text
  end

  field :constituency do
    noko.css('.post-excerpt').text.tidy
  end

  field :party do
    party_info.first
  end

  field :party_id do
    party_info.last
  end

  field :role do
    noko.xpath('.//h3[contains(.,"Designation")]/following-sibling::p').text.tidy
  end

  field :telephone do
    noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text[/Telephone:\s*(.*?)\s*$/, 1].tidy
  end

  field :fax do
    noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text[/Fax:\s*(.*?)\s*$/, 1].tidy
  end

  field :email do
    noko.xpath('.//h2[contains(.,"Contact")]/following-sibling::p').text.lines.find { |l| l.include? '@' }.tidy
  end

  field :term do
    '2013'
  end

  field :source do
    url
  end

  private

  def party_info
    party_from(noko.xpath('.//h2[contains(.,"Party")]/following-sibling::p[1]'))
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
end

def scrape_list(url)
  MembersPage.new(response: Scraped::Request.new(url: url).response).member_urls.each do |link|
    scrape_member(link)
  end
end

def scrape_member(url)
  data = MemberPage.new(response: Scraped::Request.new(url: url).response).to_h
  # puts data
  ScraperWiki.save_sqlite(%i(id term), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.barbadosparliament.com/member/listall')
