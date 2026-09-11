#!/usr/bin/env ruby

require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
LOCALE_ROOT = File.join(ROOT, "config/locales")
MESSAGE_ROOT = File.join(ROOT, "app/services/message_service")

def flatten(value, prefix = nil, output = {})
  value.each do |key, child|
    path = [ prefix, key ].compact.join(".")
    child.is_a?(Hash) ? flatten(child, path, output) : output[path] = child.to_s
  end
  output
end

def placeholders(value)
  value.scan(/%\{([a-zA-Z0-9_]+)\}/).flatten.to_set
end

errors = []
english_keys = Set.new
english_files = Dir.glob(File.join(LOCALE_ROOT, "**/*.en.yml")).sort
burmese_files = Dir.glob(File.join(LOCALE_ROOT, "**/*.my.yml")).sort

english_files.each do |english_file|
  burmese_file = english_file.sub(/\.en\.yml\z/, ".my.yml")
  unless File.exist?(burmese_file)
    errors << "missing Burmese locale: #{english_file.delete_prefix("#{ROOT}/")}"
    next
  end

  english = YAML.safe_load(File.read(english_file), aliases: true)&.fetch("en", {}) || {}
  burmese = YAML.safe_load(File.read(burmese_file), aliases: true)&.fetch("my", {}) || {}
  english = flatten(english)
  burmese = flatten(burmese)
  english_keys.merge(english.keys)

  relative = english_file.delete_prefix("#{LOCALE_ROOT}/").sub(".en.yml", "")
  (english.keys - burmese.keys).sort.each { |key| errors << "#{relative}: missing my.#{key}" }
  (burmese.keys - english.keys).sort.each { |key| errors << "#{relative}: missing en.#{key}" }

  (english.keys & burmese.keys).sort.each do |key|
    next if placeholders(english[key]) == placeholders(burmese[key])

    errors << "#{relative}.#{key}: interpolation placeholders differ"
  end
end

burmese_files.each do |burmese_file|
  english_file = burmese_file.sub(/\.my\.yml\z/, ".en.yml")
  errors << "missing English locale: #{burmese_file.delete_prefix("#{ROOT}/")}" unless File.exist?(english_file)
end

constant_count = 0
Dir.glob(File.join(MESSAGE_ROOT, "**/*.rb")).sort.each do |file|
  File.foreach(file).with_index(1) do |line, line_number|
    match = line.match(/^\s*[A-Z][A-Z0-9_]*\s*=\s*["']([a-z][a-z0-9_.]+)["']/)
    next unless match

    constant_count += 1
    key = match[1]
    errors << "#{file.delete_prefix("#{ROOT}/")}:#{line_number}: unknown locale key #{key}" unless english_keys.include?(key)
  end
end

puts "Core locale report: #{english_files.length} pairs, #{english_keys.length} keys, #{constant_count} message constants."
if errors.any?
  warn "Core locale checks failed (#{errors.length}):"
  errors.each { |error| warn "- #{error}" }
  exit 1
end

puts "Core locale checks passed."
