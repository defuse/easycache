# A simple tool that replaces all occurances of "Alice" with "Bob" in a file.
require './EasyCache.rb'

TO_REMOVE = "Alice"
TO_INSERT = "Bob"

if ARGV.length != 2
  STDERR.puts "Usage: ruby #{__FILE__} <input file> <output file>"
  exit 1
end

input_file = ARGV[0]
output_file = ARGV[1]

# Create a caching helper that stores cached objects in the ./cache directory.
unless Dir.exists? "./cache"
  Dir.mkdir( "./cache" )
end
cache = EasyCache::Cache.new( "./cache" )

# Inform the caching helper what data the block depends on.  If the input data
# hasn't been changed since the last time the block's result was cached, the
# cached object will be returned. If the block's result has never been cached or
# the input data is different, the block will be executed and its value will be
# cached.
result = cache.run( 
  EasyCache::InputSpec.new
    .data( :name_remove, TO_REMOVE )
    .data( :name_insert, TO_INSERT )
    .file( :input_file, input_file ) # <- file() looks at the file's contents.
) do 
  puts "The block executed."
  contents = File.open( input_file, "rb" ) { |f| f.read }
  contents.gsub(TO_REMOVE, TO_INSERT)
end

File.open( output_file, "wb" ) { |f| f.print result }
puts "All done."
