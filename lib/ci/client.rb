module CI
  class Client
    def initialize(options)
      @options = options
    end

    def start
      loop do
        p 'watching...'

        sleep 5
      end
    end
  end
end
