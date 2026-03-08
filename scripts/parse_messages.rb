#!/usr/bin/env ruby
# frozen_string_literal: true

# scripts/parse_messages.rb
#
# Extracts unique recruiter contacts from a LinkedIn message export (messages.csv)
# and writes a clean seed CSV to ~/Desktop/recruiters_draft.csv for annotation.
#
# Usage:
#   ruby scripts/parse_messages.rb
#
# Input:  messages.csv in the repo root (gitignored — never committed)
# Output: ~/Desktop/recruiters_draft.csv (outside repo)

require "csv"
require "date"
require "uri"

INPUT_PATH  = File.expand_path("../messages.csv", __dir__)
OUTPUT_PATH = File.expand_path("~/Desktop/recruiters_draft.csv")
MY_NAME     = "Nick Lange"
MY_SLUG     = "nicklange"

# Own addresses + noise to exclude from recruiter contact_email
MY_EMAIL_PATTERNS = [
  /nicklange/i,
  /nick\.lange/i,
  /nlange@/i,
  /nick@5l-labs/i,
  /subs@5l-labs/i,
  /jobs@wafuu/i,
  /njl@wafuu/i,
  /jobs@nicklange/i,
  /@linkedin\.com/i,
  /norepl/i,
  /noreplies/i,
  /privacy@/i,
  /survey_support@/i,
  /admissions@/i,
  /officejapan@/i,
  /\.edu$/i,
  /\.edu\b/i,
].freeze

EMAIL_RE = /\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b/

def normalize_linkedin_url(raw)
  return nil if raw.nil? || raw.strip.empty?

  url = raw.strip.sub(%r{/+$}, "")
  uri = URI.parse(url)
  URI::HTTPS.build(host: uri.host, path: uri.path).to_s
rescue URI::InvalidURIError
  raw.strip
end

def extract_company(title)
  return "" if title.nil? || title.strip.empty?

  title.split(" - ").first.strip
end

def recruiter_email?(addr)
  MY_EMAIL_PATTERNS.none? { |pat| addr.match?(pat) }
end

unless File.exist?(INPUT_PATH)
  warn "ERROR: #{INPUT_PATH} not found."
  warn "Place your LinkedIn messages export at the repo root as messages.csv"
  exit 1
end

all_rows = CSV.read(INPUT_PATH, headers: true, encoding: "bom|utf-8")

# --- Build conversation → recruiter email map ---
# Collect all recruiter-looking emails per conversation ID (from any message in thread)
conv_emails = Hash.new { |h, k| h[k] = [] }
all_rows.each do |row|
  conv_id = row["CONVERSATION ID"].to_s.strip
  next if conv_id.empty?

  emails = row["CONTENT"].to_s.scan(EMAIL_RE).select { |e| recruiter_email?(e) }
  conv_emails[conv_id].concat(emails)
end
# Deduplicate, prefer shorter/cleaner addresses (fewer tokens = less noise)
conv_emails.transform_values! do |addrs|
  addrs.map(&:downcase).uniq.min_by(&:length)
end

# --- Filter to inbound rows only ---
inbound = all_rows.reject do |row|
  from = row["FROM"].to_s.strip
  url  = row["SENDER PROFILE URL"].to_s.strip
  from == MY_NAME || url.include?(MY_SLUG)
end

inbound.each do |row|
  row["_parsed_date"] = begin
    DateTime.parse(row["DATE"].to_s)
  rescue ArgumentError
    nil
  end
end

# Group by normalized LinkedIn URL, keep earliest message per recruiter
by_url = Hash.new { |h, k| h[k] = [] }
inbound.each do |row|
  key = normalize_linkedin_url(row["SENDER PROFILE URL"])
  next if key.nil?

  by_url[key] << row
end

recruiters = by_url.map do |url, messages|
  earliest = messages.min_by { |r| r["_parsed_date"] || DateTime::Infinity.new }

  # Collect recruiter-looking emails from all conversations this person appeared in
  conv_ids = messages.map { |r| r["CONVERSATION ID"].to_s.strip }.uniq
  contact_email = conv_ids.filter_map { |id| conv_emails[id] }.first || ""

  {
    name:                 earliest["FROM"].to_s.strip,
    linkedin_url:         url,
    company_name:         extract_company(earliest["CONVERSATION TITLE"]),
    region:               "",
    conversation_subject: earliest["CONVERSATION TITLE"].to_s.strip,
    first_contact_date:   earliest["_parsed_date"]&.strftime("%Y-%m-%d") || "",
    contact_email:        contact_email,
    rating:               "",
    would_recommend:      "",
    notes:                ""
  }
end

recruiters.sort_by! { |r| r[:first_contact_date] }

CSV.open(OUTPUT_PATH, "w") do |csv|
  csv << %w[name linkedin_url company_name region conversation_subject
            first_contact_date contact_email rating would_recommend notes]
  recruiters.each do |r|
    csv << r.values_at(:name, :linkedin_url, :company_name, :region,
                       :conversation_subject, :first_contact_date,
                       :contact_email, :rating, :would_recommend, :notes)
  end
end

with_email = recruiters.count { |r| r[:contact_email] != "" }
dates = recruiters.map { |r| r[:first_contact_date] }.reject(&:empty?)
puts "Done."
puts "  Unique recruiters found  : #{recruiters.size}"
puts "  With contact email       : #{with_email}"
puts "  Date range               : #{dates.min} – #{dates.max}" unless dates.empty?
puts "  Output                   : #{OUTPUT_PATH}"
