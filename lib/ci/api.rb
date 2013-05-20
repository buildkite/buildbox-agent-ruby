module CI
  class API
    def initialize
      @i = 0
    end

    def queue
      @i += 1

      if @i == 2
        [ CI::Build.new(:project_id => 1, :build_id => 1, :repo => "git@github.com:keithpitt/mailmask-ruby", :commit => "HEAD", :command => "rspec") ]
      elsif @i == 4
        [ CI::Build.new(:project_id => 1, :build_id => 1, :repo => "git@github.com:keithpitt/mailmask-ruby", :commit => "HEAD", :command => "basdfasd  asdfasdff") ]
      else
        []
      end
    end
  end
end
