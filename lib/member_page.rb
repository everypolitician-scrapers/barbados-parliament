# frozen_string_literal: true
require 'scraped'

class MemberPage < Scraped::HTML
  field :id do
    url[/(\d+)$/, 1]
  end

  field :name do
    noko.css('h1.page-title').text.gsub(', M.P.', '').tidy
  end

  field :image do
    noko.css('div.entry-thumb img/@src').text
  end

  field :constituency do
    noko.css('.post-excerpt').text.tidy
  end

  field :party do
    return 'Democratic Labour Party' if party_id == 'DLP'
    return 'Barbados Labour Party' if party_id == 'BLP'
    raise 'Uknown party'
  end

  field :party_id do
    return 'DLP' if party_info.text.include? 'www.dlpbarbados.org'
    return 'BLP' if party_info.text.include? 'www.blp.org.bb'
    return 'BLP' if party_info.text.include? 'voteblp.com'
    return 'BLP' if party_info.css('img/@src').text.include? 'blp_logo.jpg'
    raise 'Unknown party'
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
    noko.xpath('.//h2[contains(.,"Party")]/following-sibling::p[1]')
  end
end
