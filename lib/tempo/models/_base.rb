module Tempo
  module Model

    class IdentityConflictError < Exception
    end

    class Base
      attr_reader :id

      class << self

        # Maintain an array of unique ids for the class.
        # Initialize new members with the next numberical id
        # Ids can be assigned on init (for the purpose of reading
        # in records of previous instances). An error will
        # be raised if there is already an instance with that
        # id.
        def id_counter
          @id_counter ||= 1
        end

        def ids
          @ids ||= []
        end

        def index
          @index ||= []
        end

        # example: Tempo::Model::Animal -> tempo_animals.yaml
        def file
          FileRecord::Record.model_filename( self )
        end

        def save_to_file
          FileRecord::Record.model_save( self )
        end

        def read_from_file
          file = File.join(Dir.home,'.tempo', self.file)
          instances = YAML::load_stream( File.open( file ) )
          instances.each do |i|
            new( i )
          end
        end

        # TODO: try method_missing:
        # http://www.trottercashion.com/2011/02/08/rubys-define_method-method_missing-and-instance_eval.html
        # example: Tempo::Model.find(id: 1)
        def find( key, value )
          key = "@#{key}".to_sym
          index.each do |i|
            return i if i.instance_variable_get(key) == value
          end
          nil
        end

        def delete( instance )
          id = instance.id
          index.delete( instance )
          ids.delete( id )
        end
      end

      def initialize( params={} )
        id_candidate = params[:id]
        if !id_candidate
          @id = self.class.next_id
        elsif self.class.ids.include? id_candidate
          raise IdentityConflictError, "Id #{id_candidate} already exists"
        else
          @id = id_candidate
        end
        self.class.add_id @id
        self.class.add_to_index self
      end

      # record the state of all instance variables as a hash
      def freeze_dry
        record = {}
        state = instance_variables
        state.each do |attr|
          key = attr[1..-1].to_sym
          val = instance_variable_get attr
          record[key] = val
        end
        record
      end

      def delete
        self.class.delete( self )
      end

      protected

      def self.add_to_index( member )
        @index ||= []
        @index << member
      end

      def self.add_id( id )
        @ids ||=[]
        @ids << id
        @ids.sort!
      end

      def self.increase_id_counter
        @id_counter ||= 0
        @id_counter = @id_counter.next
      end

      def self.next_id
        while ids.include? id_counter
          increase_id_counter
        end
        id_counter
      end
    end
  end
end
