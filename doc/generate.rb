#!/usr/bin/env ruby

# This script invokes Lua language server to generate doc/doc.json,
# then generates a documentation in doc/doc.md.

require 'json'
require 'uri'

PROJECT_PATH = File.expand_path("..", __dir__)
# Types to generate documentation for
RELAVANT_DEFINITIONS = %w(
    remote.windowed-cameras
    CameraViewSpec
)
# Links to external types
EXTERNAL_TYPE_LINKS = {}.merge \
    %w(LuaPlayer LuaEntity).to_h{|a| [a, "https://lua-api.factorio.com/stable/classes/#{a}.html"] },
    %w(MapPosition GuiLocation).to_h{|a| [a, "https://lua-api.factorio.com/stable/concepts/#{a}.html"] }


def add_type_links(view)
    view.gsub(/\w+/) do |type|
        if RELAVANT_DEFINITIONS.include? type
            "[#{type}](##{type})"
        elsif EXTERNAL_TYPE_LINKS.include? type
            "[#{type}](#{EXTERNAL_TYPE_LINKS[type]})"
        else
            type
        end
    end
end


system *%W(lua-language-server --doc_out_path doc --doc #{PROJECT_PATH}), out: 2, exception: true
doc_objs = JSON.load_file("#{PROJECT_PATH}/doc/doc.json")

outfile = File.open(ARGV[0] || "#{PROJECT_PATH}/doc/doc.md", 'w')
outfile.print "# API Reference\n\n"

RELAVANT_DEFINITIONS.each do |obj_name|
    doc_obj = doc_objs.find{|a| a['name'] == obj_name }

    outfile.print "## <a name=\"#{doc_obj['name']}\"></a>#{doc_obj['name']}\n\n"
    define = doc_obj['defines'][0] || {}
    outfile.print "#{define['desc']}\n\n" if define['desc']

    doc_obj['fields'].sort_by{|f| f['start']}.each do |field|

        if field['extends'] && field['extends']['type'] == 'function'
            outfile.print "### #{field['name']}\n\n"

            args = field['extends']['args'] || []
            returns = field['extends']['returns'] || []
            outfile.print "```lua\n#{doc_obj['name']}.#{field['name']}(#{args.map{|a| a['name']}.join(', ')})\n```\n\n"
                .sub(/(?<=remote\.)([\w-]+)\.(\w+)\(/, 'call("\1", "\2", ')

            outfile.print "#{field['rawdesc']}\n\n" if field['rawdesc']

            args.each do |arg|
                outfile.print "@*param* `#{arg['name']}` #{add_type_links arg['view']}"
                outfile.print " — #{arg['desc']}" if arg['desc']
                outfile.print "\n\n"
            end
            returns.each do |ret|
                outfile.print "@*return* #{add_type_links ret['view']}"
                outfile.print " — #{ret['desc']}" if ret['desc']
                outfile.print "\n\n"
            end

        else
            outfile.print "@*field* `#{field['name']}` #{add_type_links field['view']}"
            outfile.print " — #{field['desc']}" if field['desc']
            outfile.print "\n\n"
        end
    end
end
