# frozen_string_literal: true
require 'support'
require 'mustermann/file_utils'

describe Mustermann::FileUtils do
  subject(:utils) { Mustermann::FileUtils }
  include FileUtils

  before do
    @pwd     = Dir.pwd
    @tmp_dir = File.join(__dir__, 'tmp')

    mkdir_p(@tmp_dir)
    chdir(@tmp_dir)

    touch("foo.txt")
    touch("foo.rb")
    touch("bar.txt")
    touch("bar.rb")
  end

  after do
    chdir(@pwd)     if @pwd
    rm_rf(@tmp_dir) if @tmp_dir
  end

  describe :glob_pattern do
    example { utils.glob_pattern('/:foo')                 .should be == '/*'                  }
    example { utils.glob_pattern('/*foo')                 .should be == '/**/*'               }
    example { utils.glob_pattern('/(ab|c)?/:foo/d/*bar')  .should be == '/{{ab,c},}/*/d/**/*' }
    example { utils.glob_pattern('/a', '/b')              .should be == '{/a,/b}'             }
    example { utils.glob_pattern('**/*', type: :shell)    .should be == '**/*'                }
    example { utils.glob_pattern(/can't parse this/)      .should be == '**/*'                }
    example { utils.glob_pattern('/foo', type: :identity) .should be == '/foo'                }
    example { utils.glob_pattern('/fo*', type: :identity) .should be == '/fo\\*'              }
  end

  describe :glob do
    example do
      utils.glob(":name.txt").sort.should be == ['bar.txt', 'foo.txt']
    end

    example do
      extensions = []
      utils.glob("foo.:ext") { |file, params| extensions << params['ext'] }
      extensions.sort.should be == ['rb', 'txt']
    end

    example do
      utils.glob(":name.:ext", capture: { ext: 'rb', name: 'foo' }).should be == ['foo.rb']
    end
  end

  describe :glob_map do
    example do
      utils.glob_map({':name.rb' => ':name/init.rb'}).should be == {
        "bar.rb" => "bar/init.rb",
        "foo.rb" => "foo/init.rb"
      }
    end

    example do
      result   = {}
      returned = utils.glob_map({':name.rb' => ':name/init.rb'}) { |k, v| result[v] = k.upcase }
      returned.sort         .should be == ["BAR.RB", "FOO.RB"]
      result["bar/init.rb"] .should be == "BAR.RB"
    end
  end

  describe :cp do
    example do
      utils.cp({':name.rb' => ':name.ruby', ':name.txt' => ':name.md'})
      File.should be_exist('foo.ruby')
      File.should be_exist('bar.md')
      File.should be_exist('bar.txt')
    end
  end

  describe :cp_r do
    example do
      mkdir_p "foo/bar"
      utils.cp_r({'foo/:name' => :name})
      File.should be_directory('bar')
    end
  end

  describe :mv do
    example do
      utils.mv({':name.rb' => ':name.ruby', ':name.txt' => ':name.md'})
      File.should     be_exist('foo.ruby')
      File.should     be_exist('bar.md')
      File.should_not be_exist('bar.txt')
    end
  end

  describe :ln do
    example do
      utils.ln({':name.rb' => ':name.ruby', ':name.txt' => ':name.md'})
      File.should be_exist('foo.ruby')
      File.should be_exist('bar.md')
      File.should be_exist('bar.txt')
    end
  end

  describe :ln_s do
    example do
      utils.ln_s({':name.rb' => ':name.ruby', ':name.txt' => ':name.md'})
      File.should be_symlink('foo.ruby')
      File.should be_symlink('bar.md')
      File.should be_exist('bar.txt')
    end
  end

  describe :ln_sf do
    example do
      utils.ln_sf({':name.rb' => ':name.txt'})
      File.should be_symlink('foo.txt')
    end
  end
end
