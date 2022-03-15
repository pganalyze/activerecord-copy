module ActiveRecordCopy
  class MacAddress
    def initialize(str)
      str = str.strip
      if !self.class.validate_strict(str)
        raise ArgumentError.new("Invalid MAC address: #{str}")
      end
      @bytes = str.split(/[-,:]/).map { |s| s.to_i(16) }
    end

    def to_s
      @bytes.map { |h| h.hex }.join(":")
    end

    def to_bytes
      @bytes.pack('C*')
    end

    def self.validate_strict(mac)
      !!(mac =~ /^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/i)
    end
  end
end
