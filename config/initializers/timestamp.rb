module ActiveRecord
  class Base

    def update_attributes_without_timestamping(attr = {})
      class << self
        def record_timestamps; false; end
      end

      update_attributes(attr)

      class << self
        def record_timestamps; super ; end
      end
    end

  end
end