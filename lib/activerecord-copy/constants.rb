module ActiveRecordCopy
  PACKED_UINT_8 = 'C'.freeze # 8-bit unsigned (unsigned char)
  PACKED_UINT_16 = 'n'.freeze # 16-bit unsigned, network (big-endian) byte order
  PACKED_UINT_32 = 'N'.freeze # 32-bit unsigned, network (big-endian) byte order
  PACKED_UINT_64 = 'Q>'.freeze # 64-bit unsigned, big endian
  PACKED_FLOAT_32 = 'g'.freeze # single-precision, network (big-endian) byte order
  PACKED_FLOAT_64 = 'G'.freeze # double-precision, network (big-endian) byte order
  PACKED_HEX_STRING = 'H*'.freeze # hex string (high nibble first)

  INT_TYPE_OID = 23
  TEXT_TYPE_OID = 25
  UUID_TYPE_OID = 2950
  VARCHAR_TYPE_OID = 1043

  ASCII_8BIT_ENCODING = 'ASCII-8BIT'.freeze
  UTF_8_ENCODING = 'UTF-8'.freeze

  POSTGRES_EPOCH_TIME = (Time.utc(2000, 1, 1).to_f * 1_000_000).to_i
end
