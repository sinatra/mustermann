module Support
  module Projects
    include Enumerable
    extend self

    def base
      File.expand_path('../../../..', __FILE__)
    end

    def projects
      @@projects ||= Dir.chdir(base) do
        Dir['mustermann*/*.gemspec'].map { |f| File.dirname(f) }.sort
      end
    end

    def each(&block)
      projects.each(&block)
    end
  end
end
