require 'bundler/setup'
require 'mustermann/visualizer'

Hansi.mode = ARGV[0].to_i if ARGV.any?

def self.example(type, *patterns)
  print Hansi.render(:bold, "  #{type}: ".ljust(14))
  patterns.each do |pattern|
    pattern     = Mustermann.new(pattern, type: type)
    space_after = pattern.to_s.size > 24 ? " " : " " * (25 - pattern.to_s.size)
    highlight   = Mustermann::Visualizer.highlight(pattern, inspect: true)
    print highlight.to_ansi + space_after
  end
  puts
end

puts
example(:cake,     '/:prefix/**')
example(:express,  '/:prefix+/:id(\d+)', '/:page/:slug+')
example(:flask,    '/<prefix>/<int:id>', '/user/<int(min=0):id>')
example(:identity, '/image.png')
example(:pyramid,  '/{prefix:.*}/{id}',  '/{page}/*slug')
example(:rails,    '/:slug(.:ext)')
example(:regexp,   '/(?<slug>[^/]+)',    '/(?:page|user)/(\d+)')
example(:shell,    '/**/*',              '/\{a,b\}/{a,b}')
example(:simple,   '/:page/*slug')
example(:sinatra,  '/:page/*slug',         '/users/{id}?')
example(:template, '/{+pre}/{page}{?q,p}', '/users/{id}?')
puts

example(:composition)
composite = Mustermann.new("/{a}", "/{b}/{c}")
puts "  " + composite.to_ansi
puts "  " + (Mustermann.new("/") ^ composite).to_ansi
puts