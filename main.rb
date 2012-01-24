require 'rgl/adjacency'
require 'rgl/dot'

class ClassDefine
  attr_accessor :parents
  attr_reader :name

  def initialize(name)
    @name = name
    @parents = []
  end
end

class ClassTreeGraphBuilder
  def initialize(path, image_file_name)
    @header_files = find_all_header_files(path)
    @image_file_name = image_file_name
  end

  def build
    sort_headers(@header_files.sort)
    class_defines = find_all_defs(@sorted_headers)
    #class_defines = find_all_defs(@header_files)

    g = RGL::DirectedAdjacencyGraph[]
    class_defines.each do |class_define|
      class_define.parents.each do |parent|
        g.add_edge(parent, class_define.name)
      end
    end

    puts "Complete"

    g.write_to_graphic_file('png', @image_file_name)
  end

  private

  def find_all_header_files(path)
    Dir.chdir(path)
    Dir['*.h']
  end

  def find_includes(file_name)
    included_files = nil
    if File.exist?(file_name)
      File.open(file_name) do |f|
        included_files = f.read.scan(/#include\s*"([\w\.]+)"/)
      end
    end
    included_files.flatten! if included_files
    included_files
  end

  def sort_headers(header_files)
    return unless header_files

    @sorted_headers ||= []
    header_files.each do |file_name|
      next if @sorted_headers.include?(file_name)

      included_files = find_includes(file_name)
      sort_headers(included_files)
      
      @sorted_headers << file_name
    end
  end

  def find_all_defs(header_files)
    defs = []
    header_files.each do |file_name|
      File.open(file_name) do |f|
      	# находим определения классов, без параметров шаблона
        all_defs = f.read.scan(/(?:template\s*<[^>]+>\s*)?(?:class|struct)\s*(\w+)(?:\s*:\s*([\w\s,<>]+))?\s*\{/m)
        all_defs.each do |one_def|
          class_define = ClassDefine.new(one_def.shift)

          one_def.each do |all_parents_str|
          	# отрезаем параметры шаблонов
            all_parents_arr = all_parents_str.strip.gsub(/<[^>]+>/, '').split(/\s*,\s*/)
            all_parents_arr.each do |parent_str|
              parent_arr = parent_str.split(/\s+/)
              class_define.parents << parent_arr.pop
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

