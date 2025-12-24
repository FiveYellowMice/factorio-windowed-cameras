#!/usr/bin/env ruby

# This script invokes Lua language server to generate doc/doc.json,
# then generates a documentation in doc/api.adoc.

require 'json'

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


def to_id(name)
    name.gsub(/[ .-]+/, '-')
end
def add_type_links(view)
    view.gsub(/\w+/) do |type|
        if RELAVANT_DEFINITIONS.include? type
            "<<#{to_id type}>>"
        elsif EXTERNAL_TYPE_LINKS.include? type
            "#{EXTERNAL_TYPE_LINKS[type]}[#{type}]"
        else
            type
        end
    end
end


system *%W(lua-language-server --doc_out_path doc --doc #{PROJECT_PATH}), out: 2, exception: true
doc_objs = JSON.load_file("#{PROJECT_PATH}/doc/doc.json")

$> = File.open(ARGV[0] || "#{PROJECT_PATH}/doc/api.adoc", 'w')
$\ = "\n\n"
$>.print "= API Reference",
    "\n:!sectids:"

RELAVANT_DEFINITIONS.each do |obj_name|
    doc_obj = doc_objs.find{|a| a['name'] == obj_name }

    $>.print "[##{to_id doc_obj['name']}]\n", "== #{doc_obj['name']}"
    define = doc_obj['defines'][0] || {}
    $>.print "#{define['desc']}" if define['desc']

    doc_obj['fields'].sort_by{|f| f['start']}.each do |field|

        if field['extends'] && field['extends']['type'] == 'function'
            $>.print "=== #{field['name']}"

            args = field['extends']['args'] || []
            returns = field['extends']['returns'] || []
            $>.print "```lua\n#{doc_obj['name']}.#{field['name']}(#{args.map{|a| a['name']}.join(', ')})\n```"
                .sub(/(?<=remote\.)([\w-]+)\.(\w+)\(/, 'call("\1", "\2", ')

            $>.print "#{field['rawdesc']}" if field['rawdesc']

            args.each do |arg|
                $>.print "@__param__ `#{arg['name']}` #{add_type_links arg['view']}",
                    " — #{arg['desc']}" if arg['desc']
            end
            returns.each do |ret|
                $>.print "@__return__ #{add_type_links ret['view']}",
                    " — #{ret['desc']}" if ret['desc']
            end

        else
            $>.print "@__field__ `#{field['name']}` #{add_type_links field['view']}",
                " — #{field['desc']}" if field['desc']
        end
    end
end
