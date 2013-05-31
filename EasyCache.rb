require 'digest'

module EasyCache

  class Cache

    attr_reader :directory

    def initialize( directory )
      @directory = directory
    end

    def run( input_spec )
      cache_path = File.join( @directory, input_spec.digest )
      if File.exists? cache_path
        return Marshal.load( File.open( cache_path, "rb" ) { |f| f.read } )
      else
        to_cache = yield 
        File.open( cache_path, "wb" ) do |f|
          f.print Marshal.dump( to_cache )
        end
        return to_cache
      end
    end

  end

  class InputSpec

    def initialize
      @datas = Hash.new
      @files = Hash.new
    end

    def file( id, path )
      assert_symbol id
      @files[id] = hash_file( path )
      self
    end

    def data( id, value )
      assert_symbol id
      assert_unique_to_s value
      @datas[id] = value
      self
    end

    def digest
      hash = Digest::SHA256.new
      datas_sorted = @datas.to_a.sort { |a,b| a[0].to_s <=> b[0].to_s }
      files_sorted = @files.to_a.sort { |a,b| a[0].to_s <=> b[0].to_s }
      hash.update encode(
        datas_sorted.map { |k,v| encode( ["DATA", k.to_s, v.class.to_s, v.to_s] ) }
      )
      hash.update encode(
        files_sorted.map { |k,v| encode( ["FILE", k.to_s, v.class.to_s, v] ) }
      )
      return hash.hexdigest
    end

    private

    def hash_file( path )
      Digest::SHA256.new.digest( File.open( path, "rb" ) { |f| f.read } )
    end

    def assert_symbol( obj )
      unless obj.class == Symbol
        raise ArgumentError.new( "id must be a symbol" )
      end
    end

    def assert_unique_to_s( obj )
      # Unless the classes have been hacked, instances of these will have
      # a one-to-one correspondance with their to_s return value.
      unless [String, Numeric, Symbol].include? obj.class
        raise ArgumentError.new( "value may not have a one-to-one to_s" )
      end
    end

    # Encode a string array in an unambiguous way.
    def encode( str_array )
      unambiguous = "|#{str_array.length}|"
      str_array.each do |str|
        unambiguous << "|" << str.length.to_s << "|" << str
      end
      return unambiguous
      # Proof (by existance of decoding method):
      # 1. Intialize an empty array.
      # 2. Read the first |\d+|. Set 'count' to that value.
      # 3. count.times do
      # 4.     Read the next |\d+|. Set 'length' to that value.
      # 5.     Read the next 'length' characters. Add that string to the array.
      # 6. end
    end

  end

end
