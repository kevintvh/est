# encoding: utf-8
#
# Copyright (c) 2014 TechnoPark Corp.
# Copyright (c) 2014 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'nokogiri'
require 'est'
require 'tmpdir'
require 'slop'

# Est main module test.
# Author:: Yegor Bugayenko (yegor@teamed.io)
# Copyright:: Copyright (c) 2014 Yegor Bugayenko
# License:: MIT
class TestEst < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test' do |dir|
      opts = opts(['-v', '-s', dir, '-e', '**/*.png', '-r', 'max-estimate:15'])
      File.write(File.join(dir, 'a.txt'), '@todo #55 hello!')
      matches(
        Nokogiri::XML(Est::Base.new(opts).xml),
        [
          '/processing-instruction("xml-stylesheet")[contains(.,".xsl")]',
          '/puzzles/@version',
          '/puzzles/@date',
          '/puzzles[count(puzzle)=1]',
          '/puzzles/puzzle[file="a.txt"]'
        ]
      )
    end
  end

  def test_rules_failure
    Dir.mktmpdir 'test' do |dir|
      opts = opts(['-v', '-s', dir, '-e', '**/*.png', '-r', 'min-estimate:30'])
      File.write(File.join(dir, 'a.txt'), '@todo #90 hello!')
      assert_raises Est::Error do
        Est::Base.new(opts).xml
      end
    end
  end

  def opts(args)
    Slop.parse args do
      on 'v', 'verbose'
      on 's', 'source', argument: :required
      on 'e', 'exclude', as: Array, argument: :required
      on 'r', 'rule', as: Array, argument: :required
    end
  end

  def matches(xml, xpaths)
    xpaths.each do |xpath|
      fail "doesn't match '#{xpath}': #{xml}" unless xml.xpath(xpath).size == 1
    end
  end
end
