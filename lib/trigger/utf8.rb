module Trigger
  module UTF8
    # Replace or delete invalid UTF-8 characters from text, which is assumed
    # to be in UTF-8.
    #
    # The text is expected to come from external to Integrity sources such as
    # commit messages or build output.
    #
    # On ruby 1.9, invalid UTF-8 characters are replaced with question marks.
    # On ruby 1.8, if iconv extension is present, invalid UTF-8 characters
    # are removed.
    # On ruby 1.8, if iconv extension is not present, the string is unmodified.
    def self.clean(text)
      # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
      # http://stackoverflow.com/questions/9126782/how-to-change-deprecated-iconv-to-stringencode-for-invalid-utf8-correction
      if text.respond_to?(:encoding)
        # ruby 1.9
        text = text.force_encoding('utf-8').encode(intermediate_encoding, :invalid => :replace, :replace => '?').encode('utf-8')
      else
        # ruby 1.8
        # As no encoding checks are done, any string will be accepted.
        # But delete invalid utf-8 characters anyway for consistency with 1.9.
        iconv, iconv_fallback = clean_utf8_iconv
        if iconv
          begin
            output = iconv.iconv(text)
          rescue Iconv::IllegalSequence
            output = iconv_fallback.iconv(text)
          end
        end
      end
      text
    end

    # Apparently utf-16 is not available everywhere, in particular not on travis.
    # Try to find a usable encoding.
    def self.intermediate_encoding
      map = {}
      Encoding.list.each do |encoding|
        map[encoding.name.downcase] = true
      end
      %w(utf-16 utf-16be utf-16le utf-7 utf-32 utf-32le utf-32be).each do |candidate|
        if map[candidate]
          return candidate
        end
      end
      raise CannotFindEncoding, 'Cannot find an intermediate encoding for conversion to UTF-8'
    end
  end
end
