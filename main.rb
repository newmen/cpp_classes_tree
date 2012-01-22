require 'rgl/adjacency'
require 'rgl/connected_components'
require 'rgl/dot'
require 'rgl/implicit'
require 'rgl/transitivity'
require 'rgl/traversal'

#def class_graph(classes)
#  g = RGL::DirectedAdjacencyGraph[]
#  classes.each do |c|
#    g.add_edge(c.superclass, c)
#  end
#  g.write_to_graphic_file('png', 'class_graph')
#end

#class AbstractClass
#  def initialize(name)
#    @name = name
#  end
#
#  def to_s
#    @name
#  end
#end
#
#class SingleClass < AbstractClass
#  def self.instance(name)
#    @instances ||= []
#    @instances.each do |inst|
#      return inst if inst.to_s == name
#    end
#    @instances << self.new(name)
#  end
#end
#
#class MultiClass < AbstractClass
#  def self.instance(name)
#    self.new(name)
#  end
#end

class ClassDefine
  #attr_accessor :parent_names, :virtual_parent_names
  attr_accessor :parents, :virtual_parents
  attr_reader :name

  def initialize(name)
    @name = name
    #@parent_names, @virtual_parent_names = [], []
    @parents, @virtual_parents = [], []
  end
end

class ClassTreeGraphBuilder
  def initialize(path, image_file_name)
    @header_files = find_all_header_files(path)
    @image_file_name = image_file_name
  end

  def build
    class_defines = find_all_defs(@header_files)

    g = RGL::DirectedAdjacencyGraph[]
    class_defines.each do |class_define|
      class_define.parents.each do |parent|
        #g.add_edge(class_define.name, parent)
        g.add_edge(parent, class_define.name)
      end
      class_define.virtual_parents.each do |parent|
        #g.add_edge(class_define.name, parent)
        g.add_edge(parent, class_define.name)
      end
    end

    puts "Complete"

    g.write_to_graphic_file('png', @image_file_name)
  end

  private

  #def define_defines(class_defines, complete_defines)
  #  return if class_defines.empty?
  #
  #  curr_parent = complete_defines.last
  #  if curr_parent
  #
  #  elsif !curr_parent
  #    complete_defines << pop_any_parent(class_defines)
  #  end
  #
  #  define_defines(class_defines, complete_defines)
  #end

  #def pop_any_parent(class_defines)
  #  parent = nil
  #  class_defines.each do |class_define|
  #    next unless class_define.parent_names.empty? && class_define.virtual_parent_names.empty?
  #    parent = class_define
  #    break
  #  end
  #
  #  class_defines.delete(parent)
  #end

  def find_all_header_files(path)
    Dir.chdir(path)
    Dir['*.h']
  end

  def find_all_defs(header_files)
    defs = []
    header_files.each do |file_name|
      #print file_name.ljust(30)
      File.open(file_name) do |f|
        all_defs = f.read.scan(/[^\{]*(?:template\s*<[^>]+>\s*)?(?:class|struct)\s*(\w+)(?:\s*:\s*([\w\s,<>]+))?\s*\{/m)
        #p all_defs
        all_defs.each do |one_def|
          class_define = ClassDefine.new(one_def.shift)

          one_def.each do |all_parents_str|
            #all_parents_str.strip!
            #all_parents_str.gsub!(/(<[^>]+>)$/) { $1.gsub(',', ';') }
            #all_parents_arr = all_parents_str.split(/\s*,\s*/)
            all_parents_arr = all_parents_str.strip.gsub(/<[^>]+>/, '').split(/\s*,\s*/)

            all_parents_arr.each do |parent_str|
              #parent_name = parent_str.gsub(';', ',').scan(/\w+(?:\s*<[^>]+>)?$/).first
              parent_arr = parent_str.gsub(/<[^>]+>/, '').split(/\s+/)
              #parent_arr.pop
              parent_name = parent_arr.pop
              if parent_arr.include?('virtual')
                class_define.virtual_parents << parent_name
                #class_define.virtual_parent_names << parent_name
              else
                class_define.parents << parent_name
                #class_define.parent_names << parent_name
              end
            end
          end if !one_def.empty? && one_def.first

          defs << class_define
        end
      end
    end
    defs
  end
end

def main
  if ARGV.size != 2
    raise 'Wrong number of arguments'
  end

  path = ARGV[0]
  image_file_name = ARGV[1]

  graph_builder = ClassTreeGraphBuilder.new(path, image_file_name)
  graph_builder.build
end

main