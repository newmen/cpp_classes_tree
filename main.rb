# coding: utf-8

require 'rgl/adjacency'
require 'rgl/dot'
require 'docopt'

class ClassDefine
  attr_accessor :parents
  attr_reader :name

  def initialize(name)
    @name = name
    @parents = []
  end
end

class ClassTreeGraphBuilder
  def initialize(path, image_file_name, recursive_find)
    @path_to_project = path
    @header_files = find_all_header_files(path, recursive_find)
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

    g.write_to_graphic_file('png', "#@path_to_project/#@image_file_name")
  end

  private

  def find_all_header_files(dir, recursive_find)
    result = Dir["#{dir}/*.h"]
    if recursive_find
      # i like it %)
      result | Dir["#{dir}/*/"].inject([]) do |acc, inner_dir|
        acc | find_all_header_files(inner_dir, recursive_find)
      end
    else
      result
    end
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
    @visited_files ||= []
    header_files.each do |file_name|
      next if @sorted_headers.include?(file_name)

      unless @visited_files.include?(file_name)
        included_files = find_includes(file_name)
        @visited_files << file_name
        sort_headers(included_files)
      end

      @sorted_headers << file_name
      @visited_files.clear
    end
  end

  def find_all_defs(header_files)
    defs = []
    header_files.each do |file_name|
      next unless File.exist?(file_name)
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
  doc = <<HEREHELP
Usage:
  #{__FILE__} [options]

Options:
  -h, --help             Этот хелп
  -d, --dir=DIR          Директория проекта, например ~/c++/hello_world
  -i, --image_name=NAME  Название граф-файла [default: classes_tree]
  -r, --recursive        Искать файлы рекурсивно
HEREHELP

  begin
    options = Docopt::docopt(doc)

    graph_builder = ClassTreeGraphBuilder.new(options['--dir'],
                                              options['--image_name'],
                                              options['--recursive'])
    graph_builder.build
  rescue Docopt::Exit => e
    puts e.message
  end
end

main

