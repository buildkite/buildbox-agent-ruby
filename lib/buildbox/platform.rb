module Buildbox
  class Platform
    class << self
      [:cygwin, :darwin, :bsd, :freebsd, :linux, :solaris].each do |type|
        define_method("#{type}?") do
          platform.include?(type.to_s)
        end
      end

      def windows?
        %W[mingw mswin].each do |text|
          return true if platform.include?(text)
        end

        false
      end

      def platform
        RbConfig::CONFIG["host_os"].downcase
      end
    end
  end
end
