require 'nokogiri'
require 'codemodels'

module CodeModels
module Xml

class Parser < CodeModels::Parser

    def internal_parse_artifact(artifact)
        raw_ast = Nokogiri.XML(artifact.code)
        convert_raw_ast(raw_ast)
    end

    def convert_raw_ast(raw_node)
        if raw_node.is_a?(Nokogiri::XML::Document)
            build_document(raw_node)
        elsif raw_node.is_a?(Nokogiri::XML::Element)
            build_element(raw_node)
        elsif raw_node.is_a?(Nokogiri::XML::Text)
            build_text(raw_node)            
        elsif raw_node.is_a?(Nokogiri::XML::Attr)
            build_attribute(raw_node)                        
        else
            raise "Unknown node type #{raw_node.class}"
        end
    end

    def build_attribute(raw_node)
        node = Attribute.new
        node.name = raw_node.name
        node.value = raw_node.value
        node
    end

    def build_text(raw_node)
        node = Text.new
        node
    end

    def build_element(raw_node)
        node = Element.new
        node.name = raw_node.name
        raw_node.attribute_nodes.each do |c|
            node.addAttributes(convert_raw_ast(c))
        end
        raw_node.children.each do |c|
            if c.is_a?(Nokogiri::XML::Text)
                node.addTexts(convert_raw_ast(c))
            elsif c.is_a?(Nokogiri::XML::Element)
                node.addChildren(convert_raw_ast(c))
            else
                raise "Unexpected child type: #{c.class}"
            end
        end
        node
    end

    def build_document(raw_node)
        node = Document.new
        node.version = raw_node.version
        node.encoding = raw_node.encoding
        for n in raw_node.namespaces
            node.addNamespaces(convert_raw_ast(n))
        end
        node.root = convert_raw_ast(raw_node.root)
        node
    end

end

DefaultParser = Parser.new

def self.jsonize_node(node)
    map = {}
    
    map['name'] = node.name
    map['blank'] = node.blank?
    map['cdata'] = node.cdata?
    map['comment'] = node.comment?
    map['content'] = node.content
    map['fragment'] = node.fragment?
    map['is_text'] = node.text?
    map['text'] = node.text
    map['type'] = node.type

    namespaces = []
    node.namespace_definitions.each do |n|
            namespaces << { 'href' => n.href, 'prefix' => n.prefix}
    end
    map['namespaces'] = namespaces

    attrs = []
    node.attribute_nodes.each do |a|
            attr_map = {}
            attr_map['value'] = a.value
            attr_map['name'] = a.name
            attrs << attr_map
    end
    map['attributes'] = attrs

    children = []
    node.children.each do |c|
            children << jsonize_node(c)
    end
    map['children'] = children 

    map
end

def self.jsonize_doc(doc)
    map = {}
    map['namespaces'] = doc.namespaces
    map['version'] = doc.version
    map['encoding'] = doc.encoding
    map['root'] = jsonize_node(doc.root)
    map
end

end
end