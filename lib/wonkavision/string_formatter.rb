module Wonkavision
  class StringFormatter

    class << self

      def format(val,format,opts)
        return val.to_s unless format

        formatter = formats[format] || format
        default_formatter = formats[:default]

        formatter.respond_to?(:call) ? formatter.call(val,format,opts) :
          default_formatter.call(val,formatter,opts)

      end

      def formats
        @formats ||=
          HashWithIndifferentAccess.new(
                                        :default=>lambda{|v,f,opts| v.respond_to?(:strftime) ?
                                          v.strftime(f.to_s) : f.to_s % v } ,
                                        :float =>lambda {|v,f,opts| precision_format(opts) % v },
                                        :integer => lambda {|v,f,opts| precision_format(opts,0) % v },
                                        :dollars=>lambda {|v,f,opts|
                                          to_currency(v, '$', ',', '.', precision_format(opts,2))},
                                        :percent=>lambda {|v,f,opts|
                                          "#{precision_format(opts,1)}%%" % (v.to_f*100.0)},
                                        :yes_no=>lambda {|v,f,opts| v ? "Yes" : "No"}
                                        )
      end

      private
      def precision_format(opts,default_precision=nil)
        precision = opts[:precision] || default_precision
        "%#{precision ? "." + precision.to_s : default_precision}f"
      end


      def to_currency( val, pre_symbol='$', thousands=',', decimal='.', precision_format='%.2f', post_symbol=nil )
        "#{pre_symbol}#{( precision_format % val ).gsub(/(\d)(?=(?:\d{3})+(?:$|\.))/,"\\1#{thousands}")}#{post_symbol}"
      end

    end
  end
end
