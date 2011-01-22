# This class is based off of
# https://github.com/josephruscio/aggregate and
# https://github.com/afurmanov/aggregate
#
# Copyright (c) 2009 Joseph Ruscio
#
#Permission is hereby granted, free of charge, to any person
#obtaining a copy of this software and associated documentation
#files (the "Software"), to deal in the Software without
#restriction, including without limitation the rights to use,
#copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the
#Software is furnished to do so, subject to the following
#conditions:
#
#The above copyright notice and this permission notice shall be
#included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#OTHER DEALINGS IN THE SOFTWARE.

module Wonkavision
  module Plugins
    module Aggregation
      class Measure
        #The current average of all samples
        attr_reader :mean

        #The current number of samples
        attr_reader :count

        #The maximum sample value
        attr_reader :max

        #The minimum samples value
        attr_reader :min

        #The sum of all samples
        attr_reader :sum

        #The number of samples falling below the lowest valued histogram bucket
        attr_reader :outliers_low

        #The number of samples falling above the highest valued histogram bucket
        attr_reader :outliers_high

        DEFAULT_LOG_BUCKETS = 8

        # The number of buckets in the binary logarithmic histogram (low => 2**0, high => 2**@@LOG_BUCKETS)
        def log_buckets
          @log_buckets
        end

        # Create a new Aggregate that maintains a binary logarithmic histogram
        # by default. Specifying values for low, high, and width configures
        # the aggregate to maintain a linear histogram with (high - low)/width buckets
        def initialize (options={})
          low = options[:low]
          high = options[:high]
          width = options[:width]
          @log_buckets = options[:log_buckets] || DEFAULT_LOG_BUCKETS
          @count = 0
          @sum = 0.0
          @sum2 = 0.0
          @outliers_low = 0
          @outliers_high = 0

          # If the user asks we maintain a linear histogram where
          # values in the range [low, high) are bucketed in multiples
          # of width
          if (nil != low && nil != high && nil != width)

            #Validate linear specification
            if high <= low
              raise ArgumentError, "High bucket must be > Low bucket"
            end

            if high - low < width
              raise ArgumentError, "Histogram width must be <= histogram range"
            end

            if 0 != (high - low).modulo(width)
              raise ArgumentError, "Histogram range (high - low) must be a multiple of width"
            end

            @low = low
            @high = high
            @width = width
          else
            low ||= 1
            @low = 1
            @low = to_bucket(to_index(low))
            @high = to_bucket(to_index(@low) + log_buckets - 1)
          end

          #Initialize all buckets to 0
          @buckets = Array.new(bucket_count, 0)
        end

        # Include a sample in the aggregate
        def add data

          # Update min/max
          if 0 == @count
            @min = data
            @max = data
          else
            @max = [data, @max].max
            @min = [data, @min].min
          end

          # Update the running info
          @count += 1
          @sum += data
          @sum2 += (data * data)

          # Update the bucket
          @buckets[to_index(data)] += 1 unless outlier?(data)
        end
        alias << add

        def reject(data)
          @min = Wonkavision::NaN
          @max = Wonkavision::NaN
          @count -= 1
          @sum -= data
          @sum2 -= (data * data)
          @buckets[to_index(data)] -= 1 unless outlier?(data, true)
        end
        alias >> reject

        def mean
          @sum / @count
        end

        #Calculate the standard deviation
        def std_dev
          return Wonkavision::NaN unless @count > 1
          Math.sqrt((@sum2.to_f - ((@sum.to_f * @sum.to_f)/@count.to_f)) / (@count.to_f - 1))
        end

        #Iterate through each bucket in the histogram regardless of
        #its contents
        def each
          @buckets.each_with_index do |count, index|
            yield(to_bucket(index), count)
          end
        end

        #Iterate through only the buckets in the histogram that contain
        #samples
        def each_nonzero
          @buckets.each_with_index do |count, index|
            yield(to_bucket(index), count) if count != 0
          end
        end

        # log2(x) returns j, | i = j-1 and 2**i <= data < 2**j
        @@LOG2_DIVEDEND = Math.log(2)
        def self.log2( x )
          Math.log(x) / @@LOG2_DIVEDEND
        end
        private

        def linear?
          nil != @width
        end

        def outlier? (data, remove=false)
          delta = remove ? -1 : 1
          if data < @low
            @outliers_low += delta
          elsif data >= @high
            @outliers_high += delta
          else
            return false
          end
        end

        def bucket_count
          if linear?
            return (@high-@low)/@width
          else
            return log_buckets
          end
        end

        def to_bucket(index)
          if linear?
            return @low + (index * @width)
          else
            return 2**(log2(@low) + index)
          end
        end

        def right_bucket? index, data

          # check invariant
          raise unless linear?

          bucket = to_bucket(index)

          #It's the right bucket if data falls between bucket and next bucket
          bucket <= data && data < bucket + @width
        end

        # A data point is added to the bucket[n] where the data point
        # is less than the value represented by bucket[n], but greater
        # than the value represented by bucket[n+1]

        def to_index (data)

          # basic case is simple
          return log2([1,data/@low].max).to_i if !linear?

          # Search for the right bucket in the linear case
          @buckets.each_with_index do |count, idx|
            return idx if right_bucket?(idx, data)
          end
          #find_bucket(0, bucket_count-1, data)

          #Should not get here
          raise "#{data}"
        end

        def log2(x)
          self.class.log2(x)
        end

      end
    end
  end
end

