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
        MessageMapper::Map.new.execute(data_source, map_block)
      end

      def register_map_directory(directory_path, recursive=true)
        searcher = "#{recursive ? "*" : "**/*"}.rb"
        Dir[File.join(directory_path,searcher)].each {|map| require map}
      end
    end

  end
end
