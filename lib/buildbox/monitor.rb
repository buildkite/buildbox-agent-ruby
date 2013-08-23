require 'celluloid'

class Monitor
  include Celluloid

  def initialize(build, api)
    @build = build
    @api   = api
  end

  def monitor
    loop do
      @api.update_build(@build) if build_started?

      if build_finished?
        break
      else
        sleep 1
      end
    end
  end

  private

  def build_started?
    @build.output != nil
  end

  def build_finished?
    @build.exit_status != nil
  end
end
