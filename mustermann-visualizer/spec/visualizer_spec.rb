require 'support'
require 'mustermann/visualizer'

describe Mustermann::Visualizer do
  subject(:highlight) { Mustermann::Visualizer.highlight(pattern) }
  before { Hansi.mode = 256 }
  after  { Hansi.mode = nil }

  describe :highlight do
    context :sinatra do
      context "/a" do
        let(:pattern) { Mustermann.new("/a") }
        its(:to_ansi)    { should be == "\e[0m\e[38;5;246m\e[38;5;246m\e[38;5;247m/\e[0m\e[38;5;246m\e[38;5;246m\e[38;5;246ma\e[0m" }
        its(:to_html)    { should be == '<span style="color: #839496;"><span style="color: #93a1a1;">/</span><span style="color: #839496;">a</span></span></span>' }
        its(:to_sexp)    { should be == '(root (separator /) (char a))' }
        its(:to_pattern) { should be == pattern }
        its(:to_s)       { should be == "/a" }
        its(:stylesheet) { should include(".mustermann_pattern .mustermann_illegal {\n  color: #8b0000;") }

        example do
          highlight.to_html(css: false).should be == 
            '<span class="mustermann_pattern"><span class="mustermann_root"><span class="mustermann_separator">/</span><span class="mustermann_char">a</span></span></span>'
        end

        example do
          renderer = Mustermann::Visualizer::Renderer::Generic
          result   = highlight.render_with(renderer)
          result.should be == pattern.to_s
        end
      end

      context '/:name' do
        let(:pattern) { Mustermann.new("/:name") }
        its(:to_sexp) { should be == "(root (separator /) (capture : (name name)))" }
      end

      context '/{name}' do
        let(:pattern) { Mustermann.new("/{name}") }
        its(:to_sexp) { should be == "(root (separator /) (capture { (name name) }))" }
      end

      context '/{+name}' do
        let(:pattern) { Mustermann.new("/{+name}") }
        its(:to_sexp) { should be == "(root (separator /) (named_splat {+ (name name) }))" }
      end

      context ':user(@:host)?' do
        let(:pattern) { Mustermann.new(':user(@:host)?') }
        its(:to_sexp) { should be == '(root (capture : (name user)) (optional (group "(" (char @) (capture : (name host)) ")") ?))' }
      end

      context 'a b' do
        let(:pattern) { Mustermann.new('a b') }
        its(:to_sexp) { should be == '(root (char a) (char " ") (char b))' }
      end

      context 'a|b' do
        let(:pattern) { Mustermann.new('a|b') }
        its(:to_sexp) { should be == '(root (union (char a) | (char b)))' }
      end

      context '(a|b)' do
        let(:pattern) { Mustermann.new('(a|b)c') }
        its(:to_sexp) { should be == '(root (union "(" (char a) | (char b) ")") (char c))' }
      end

      context '\:a' do
        let(:pattern) { Mustermann.new('\:a') }
        its(:to_sexp) { should be == '(root (escaped "\\\\" (escaped_char :)) (char a))' }
      end
    end

    context :regexp do
      context 'a' do
        let(:pattern) { Mustermann.new('a', type: :regexp) }
        its(:to_sexp) { should be == '(root (char a))' }
      end

      context '/(\d+)' do
        let(:pattern) { Mustermann.new('/(\d+)', type: :regexp) }
        its(:to_sexp) { should be == '(root (separator /) (capture "(" (special "\\\\d") (special +))))' }
      end

      context '\A' do
        let(:pattern) { Mustermann.new('\A', type: :regexp, check_anchors: false) }
        its(:to_sexp) { should be == '(root (illegal "\\\\A"))' }
      end

      context '(?<name>.)\g<name>' do
        let(:pattern) { Mustermann.new('(?<name>.)\g<name>', type: :regexp) }
        its(:to_sexp) { should be == '(root (capture "(?<" (name name) >(special .))) (special "\\\\g<name>"))' }
      end

      context '\p{Ll}' do
        let(:pattern) { Mustermann.new('\p{Ll}', type: :regexp) }
        its(:to_sexp) { should be == '(root (special "\\\\p{Ll}"))' }
      end

      context '\/' do
        let(:pattern) { Mustermann.new('\/', type: :regexp) }
        its(:to_sexp) { should be == '(root (separator /))' }
      end

      context '\[' do
        let(:pattern) { Mustermann.new('\[', type: :regexp) }
        its(:to_sexp) { should be == '(root (escaped "\\\\" (escaped_char [)))' }
      end

      context '^' do
        let(:pattern) { Mustermann.new('^', type: :regexp, check_anchors: false) }
        its(:to_sexp) { should be == '(root (illegal ^))' }
      end

      context '(?-mix:.)' do
        let(:pattern) { Mustermann.new('(?-mix:.)', type: :regexp) }
        its(:to_sexp) { should be == '(root (special "(?-mix:") (special .) (special ")"))' }
      end

      context '[a\d]' do
        let(:pattern) { Mustermann.new('[a\d]', type: :regexp) }
        its(:to_sexp) { should be == '(root (special [) (char a) (special "\\\\d") (special ]))' }
      end

      context '[^a-z]' do
        let(:pattern) { Mustermann.new('[^a-z]', type: :regexp) }
        its(:to_sexp) { should be == '(root (special [) (special ^) (char a) (special -) (char z) (special ]))' }
      end

      context '[[:digit:]]' do
        let(:pattern) { Mustermann.new('[[:digit:]]', type: :regexp) }
        its(:to_sexp) { should be == '(root (special [[:digit:]]))' }
      end

      context 'a{1,}' do
        let(:pattern) { Mustermann.new('a{1,}', type: :regexp) }
        its(:to_sexp) { should be == "(root (char a) (special {1,}))" }
      end
    end

    context :template do
      context '/{name}' do
        let(:pattern) { Mustermann.new("/{+foo,bar*}", type: :template) }
        its(:to_sexp) { should be == "(root (separator /) (expression {+ (variable (name foo)) , (variable (name bar) *) }))" }
      end
    end

    context "custom AST based pattern" do
      let(:my_type) { Class.new(Mustermann::AST::Pattern) { on('x') { |*| node(:char, "o") } }}
      let(:pattern) { Mustermann.new("fxx", type: my_type) }
      its(:to_sexp) { should be == "(root (char f) (escaped x) (escaped x))" }
    end

    context "without known highlighter" do
      let(:pattern) { Mustermann::Pattern.new("foo") }
      its(:to_sexp) { should be == "(root (unknown foo))" }
    end

    context :composite do
      let(:pattern) { Mustermann.new(":a", ":b") ^ Mustermann.new(":c") }
      its(:to_sexp) do
        should be == '(composite (quote "(") (composite (type sinatra:) (quote "\\"") '         \
          '(root (capture : (name a))) (quote "\\"") (quote " | ") (type sinatra:) (quote '     \
          '"\\"") (root (capture : (name b))) (quote "\\"")) (quote ")") (quote " ^ ") (type '  \
          'sinatra:) (quote "\\"") (root (capture : (name c))) (quote "\\""))'
      end
    end
  end

  describe :tree do
    subject(:tree) { Mustermann::Visualizer.tree(pattern) }

    context :sinatra do
      context "/:a(@:b)" do
        let(:pattern) { Mustermann.new("/:a(@:b)") }
        let(:tree_data) do
          <<-TREE.gsub(/^\s+/, '')
            \e[38;5;61m\e[0m\e[38;5;100mroot\e[0m             \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\e[4m\e[38;5;100m/:a(@:b)\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\"  \e[0m
            \e[38;5;61m└ \e[0m\e[38;5;166mpayload\e[0m                    
            \e[38;5;61m  ├ \e[0m\e[38;5;100mseparator\e[0m    \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\e[4m\e[38;5;100m/\e[0m\e[38;5;66m\e[38;5;242m:a(@:b)\e[0m\e[38;5;66m\"  \e[0m
            \e[38;5;61m  ├ \e[0m\e[38;5;100mcapture\e[0m      \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m/\e[0m\e[38;5;66m\e[4m\e[38;5;100m:a\e[0m\e[38;5;66m\e[38;5;242m(@:b)\e[0m\e[38;5;66m\"  \e[0m
            \e[38;5;61m  └ \e[0m\e[38;5;100mgroup\e[0m        \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m/:a\e[0m\e[38;5;66m\e[4m\e[38;5;100m(@:b)\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\"  \e[0m
            \e[38;5;61m    └ \e[0m\e[38;5;166mpayload\e[0m                
            \e[38;5;61m      ├ \e[0m\e[38;5;100mchar\e[0m     \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m/:a(\e[0m\e[38;5;66m\e[4m\e[38;5;100m@\e[0m\e[38;5;66m\e[38;5;242m:b)\e[0m\e[38;5;66m\"  \e[0m
            \e[38;5;61m      └ \e[0m\e[38;5;100mcapture\e[0m  \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m/:a(@\e[0m\e[38;5;66m\e[4m\e[38;5;100m:b\e[0m\e[38;5;66m\e[38;5;242m)\e[0m\e[38;5;66m\"  \e[0m
          TREE
        end
        its(:to_s) { should be == tree_data }
      end
    end

    context :shell do
      context "/**/*" do
        let(:pattern) { Mustermann.new("/**/*", type: :shell) }
        let(:tree_data) { "\e[38;5;61m\e[0m\e[38;5;100mpattern (not AST based)\e[0m  \e[0m\e[38;5;66m\"\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\e[4m\e[38;5;100m/**/*\e[0m\e[38;5;66m\e[38;5;242m\e[0m\e[38;5;66m\"  \e[0m\n" }
        its(:to_s) { should be == tree_data }
      end
    end
  end
end