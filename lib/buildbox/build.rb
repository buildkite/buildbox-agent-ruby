module Buildbox
  class Build
    include Buildbox::Model

    attr_accessor :id, :script, :env, :namespace,
      :started_at, :output, :exit_status, :finished_at,
      :process, :artifact_paths

    def success?
      exit_status == 0
    end

    def cancelling?
      cancel_started == true
    end

    def started?
      !started_at.nil?
    end

    def finished?
      !finished_at.nil?
    end
  end
end
