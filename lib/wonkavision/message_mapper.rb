module Wonkavision

  module MessageMapper

    class << self
      def maps
        @maps ||={}
      end

      def register(map_name,&block)
        MessageMapper.maps[map_name] = block
      end

      def execute(map,data_source)
        map_block = map.kind_of?(Proc) ? map : MessageMapper.maps[map]

        raise "#{map} not found" unless map_block
        message = MessageMapper::Map.new(data_source)
        message.instance_eval(&map_block)
        message.instance_variable_set("@context_stack", [])
        message
      end

      def register_map_directory(directory_path, recursive=true)
        searcher = "#{recursive ? "*" : "**/*"}.rb"
        Dir[File.join(directory_path,searcher)].each {|map| require map}
      end
    end

  end
end
