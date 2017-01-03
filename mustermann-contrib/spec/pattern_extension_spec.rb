# frozen_string_literal: true
require 'support'
require 'mustermann/visualizer'
require 'pp'
require 'stringio'

describe Mustermann::Visualizer::PatternExtension do
  subject(:pattern) { Mustermann.new("/:name") }
  before { Hansi.mode = 16  }
  after  { Hansi.mode = nil }

  specify :to_ansi do
    pattern.to_ansi(inspect: true,  capture: :red,   default: nil).should be == "\e[0m\"\e[0m/\e[0m\e[91m:\e[0m\e[91mname\e[0m\"\e[0m"
    pattern.to_ansi(inspect: false, capture: :green, default: nil).should be == "\e[0m/\e[0m\e[32m:\e[0m\e[32mname\e[0m"
    pattern.to_ansi(inspect: nil,   capture: :green, default: nil).should be == "\e[0m/\e[0m\e[32m:\e[0m\e[32mname\e[0m"
  end

  specify :to_html do
    pattern.to_html(css: false, class_prefix: "", tag: :tt).should be == '<tt class="pattern"><tt class="root"><tt class="separator">/</tt><tt class="capture">:<tt class="name">name</tt></tt></tt></tt>'
  end

  specify :to_tree do
    pattern.to_tree.should be == Mustermann::Visualizer.tree(pattern).to_s
  end

  specify :color_inspect do
    pattern.color_inspect.should include(pattern.to_ansi(inspect: true))
    pattern.color_inspect.should include("#<Mustermann::Sinatra:")
  end

  specify :to_s do
    object = Class.new { def puts(arg) arg.to_s end }.new
    object.puts(pattern).should be == pattern.to_ansi
  end

  context :pretty_print do
    before(:all) { ColorPrinter = Class.new(::PP) }
    let(:output) { StringIO.new }

    specify 'with color printer' do
      ColorPrinter.new(output, 79).pp(pattern)
      output.string.should be == pattern.color_inspect
    end

    specify 'without color printer' do
      ::PP.new(output, 79).pp(pattern)
      output.string.should be == pattern.inspect
    end
  end
end
