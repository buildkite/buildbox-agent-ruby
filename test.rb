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
  build = CI::Build.new(:project_id => 1, :build_id => 1, :repo => "git@github.com:keithpitt/mailmask-ruby.git", :commit => "741205178cf3749a23bd0780d4a432372d601013", :command => "rspec")
  result = build.start do |output|
    print ansi_color_codes(output)
  end

  # p result
end

[ f ].each &:join
