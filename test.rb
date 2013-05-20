lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ci'

logger = Logger.new(STDOUT)

# thanks integrity!
def ansi_color_codes(string)
  string.gsub("\e[0m", '').
    gsub(/\e\[(\d+)m/, "")
end

f = Thread.new do
  build = CI::Build.new(1, 1, "git@github.com:keithpitt/mailmask-ruby.git", "741205178cf3749a23bd0780d4a432372d601013", "rspec")
  result = build.start do |output|
    print ansi_color_codes(output)
  end

  # p result
end

s = Thread.new do
  build2 = CI::Build.new(2, 2, "git@github.com:compactcode/mailmask.git", "67b15b704e04e2b40c1498bbb9d2a0a6608f8d16", "bundle && bundle exec rake")
  result = build2.start do |output|
    print ansi_color_codes(output)
  end

  p result
end

[ f, s ].each &:join
