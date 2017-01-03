# frozen_string_literal: true
require 'mustermann'
require 'mustermann/file_utils/glob_pattern'
require 'mustermann/mapper'
require 'fileutils'

module Mustermann
  # Implements handy file operations using patterns.
  module FileUtils
    extend self

    # Turn a Mustermann pattern into glob pattern.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   Mustermann::FileUtils.glob_pattern('/:name')                  # => '/*'
    #   Mustermann::FileUtils.glob_pattern('src/:path/:file.(js|rb)') # => 'src/**/*/*.{js,rb}'
    #   Mustermann::FileUtils.glob_pattern('{a,b}/*', type: :shell)   # => '{a,b}/*'
    #
    #   pattern = Mustermann.new('/foo/:page', '/bar/:page') # => #<Mustermann::Composite:...>
    #   Mustermann::FileUtils.glob_pattern(pattern)          # => "{/foo/*,/bar/*}"
    #
    # @param [Object] pattern the object to turn into a glob pattern.
    # @return [String] the glob pattern
    def glob_pattern(*pattern, **options)
      pattern_with_glob_pattern(*pattern, **options).last
    end

    # Uses the given pattern(s) to search for files and directories.
    #
    # @example
    #   require 'mustermann/file_utils'
    #   Mustermann::FileUtils.glob(':base.:ext') # => ['example.txt']
    #
    #   Mustermann::FileUtils.glob(':base.:ext') do |file, params|
    #     file   # => "example.txt"
    #     params # => {"base"=>"example", "ext"=>"txt"}
    #   end
    def glob(*pattern, **options, &block)
      raise ArgumentError, "no pattern given" if pattern.empty?
      pattern, glob_pattern = pattern_with_glob_pattern(*pattern, **options)
      results               = [] unless block
      Dir.glob(glob_pattern) do |result|
        next unless params = pattern.params(result)
        block ? block[result, params] : results << result
      end
      results
    end

    # Allows to search for files an map these onto other strings.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   Mustermann::FileUtils.glob_map(':base.:ext' => ':base.bak.:ext') # => {'example.txt' => 'example.bak.txt'}
    #   Mustermann::FileUtils.glob_map(':base.:ext' => :base) { |file, mapped| mapped } # => ['example']
    #
    # @see Mustermann::Mapper
    def glob_map(map = {}, **options, &block)
      map    = Mapper === map ? map : Mapper.new(map, **options)
      mapped = glob(*map.to_h.keys).map { |f| [f, unescape(map[f])] }
      block ? mapped.map(&block) : Hash[mapped]
    end

    # Copies files based on a pattern mapping.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # copies example.txt to example.bak.txt
    #   Mustermann::FileUtils.cp(':base.:ext' => ':base.bak.:ext')
    #
    # @see #glob_map
    def cp(map = {}, recursive: false, **options)
      utils_opts, opts = split_options(:preserve, :dereference_root, :remove_destination, **options)
      cp_method        = recursive ? :cp_r : :cp
      glob_map(map, **opts) { |o,n| f.send(cp_method, o, n, **utils_opts) }
    end


    # Copies files based on a pattern mapping, recursively.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # copies Foo.app/example.txt to Foo.back.app/example.txt
    #   Mustermann::FileUtils.cp_r(':base.:ext' => ':base.bak.:ext')
    #
    # @see #glob_map
    def cp_r(map = {}, **options)
      cp(map, recursive: true, **options)
    end

    # Moves files based on a pattern mapping.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # moves example.txt to example.bak.txt
    #   Mustermann::FileUtils.mv(':base.:ext' => ':base.bak.:ext')
    #
    # @see #glob_map
    def mv(map = {}, **options)
      utils_opts, opts = split_options(**options)
      glob_map(map, **opts) { |o,n| f.mv(o, n, **utils_opts) }
    end


    # Creates links based on a pattern mapping.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # creates a link from bin/example to lib/example.rb
    #   Mustermann::FileUtils.ln('lib/:name.rb' => 'bin/:name')
    #
    # @see #glob_map
    def ln(map = {}, symbolic: false, **options)
      utils_opts, opts = split_options(**options)
      link_method      = symbolic ? :ln_s : :ln
      glob_map(map, **opts) { |o,n| f.send(link_method, o, n, **utils_opts) }
    end

    # Creates symbolic links based on a pattern mapping.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # creates a symbolic link from bin/example to lib/example.rb
    #   Mustermann::FileUtils.ln_s('lib/:name.rb' => 'bin/:name')
    #
    # @see #glob_map
    def ln_s(map = {}, **options)
      ln(map, symbolic: true, **options)
    end

    # Creates symbolic links based on a pattern mapping.
    # Overrides potentailly existing files.
    #
    # @example
    #   require 'mustermann/file_utils'
    #
    #   # creates a symbolic link from bin/example to lib/example.rb
    #   Mustermann::FileUtils.ln_sf('lib/:name.rb' => 'bin/:name')
    #
    # @see #glob_map
    def ln_sf(map = {}, **options)
      ln(map, symbolic: true, force: true, **options)
    end


    # Splits options into those meant for Mustermann and those
    # meant for ::FileUtils.
    #
    # @!visibility private
    def split_options(*utils_option_names, **options)
      utils_options, pattern_options = {}, {}
      utils_option_names += %i[force noop verbose]

      options.each do |key, value|
        list = utils_option_names.include?(key) ? utils_options : pattern_options
        list[key] = value
      end

      [utils_options, pattern_options]
    end

    # Create a Mustermann pattern from whatever the input is and turn it into
    # a glob pattern.
    #
    # @!visibility private
    def pattern_with_glob_pattern(*pattern, **options)
      options[:uri_decode]    ||= false
      pattern                   = Mustermann.new(*pattern.flatten, **options)
      @glob_patterns          ||= {}
      @glob_patterns[pattern] ||= GlobPattern.generate(pattern)
      [pattern, @glob_patterns[pattern]]
    end

    # The FileUtils method to use.
    # @!visibility private
    def f
      ::FileUtils
    end

    # Unescape an URI escaped string.
    # @!visibility private
    def unescape(string)
      @uri ||= URI::Parser.new
      @uri.unescape(string)
    end

    # Create a new version of Mustermann::FileUtils using a different ::FileUtils module.
    # @see DryRun
    # @!visibility private
    def with_file_utils(&block)
      Module.new do
        include Mustermann::FileUtils
        define_method(:f, &block)
        private(:f)
        extend self
      end
    end

    private :pattern_with_glob_pattern, :split_options, :f, :unescape

    alias_method :copy,     :cp
    alias_method :move,     :mv
    alias_method :link,     :ln
    alias_method :symlink,  :ln_s
    alias_method :[],       :glob

    DryRun  ||= with_file_utils { ::FileUtils::DryRun  }
    NoWrite ||= with_file_utils { ::FileUtils::NoWrite }
    Verbose ||= with_file_utils { ::FileUtils::Verbose }
  end
end
