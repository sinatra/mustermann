module Support
  module ScanMatcher
    extend RSpec::Matchers::DSL

    def scan(pattern, options = {})
      give_scan_result(:scan, pattern, options)
    end

    def check(pattern, options = {})
      give_scan_result(:check, pattern, options)
    end

    def scan_until(pattern, options = {})
      give_scan_result(:scan_until, pattern, options)
    end

    def check_until(pattern, options = {})
      give_scan_result(:check_until, pattern, options)
    end

    matcher :give_scan_result do |method_name, pattern, options = {}|
      def result_expectations
        @result_expectations ||= []
      end

      def expect_result(description, expected, &block)
        result_expectations << Proc.new do |result|
          if !block.call(result)
            "expected %p to %s %p matching %s" % [ result.scanner, method_name, pattern, description ]
          end
        end
      end

      match do |scanner|
        scanned = scanner.public_send(method_name, pattern, options)
        scanned and result_expectations.all? { |e| !e.call(scanned) }
      end

      chain(:matching_substring) do |substring|
        expected_result("the substring %p" % substring) { |r| r.to_s == substring }
      end

      chain(:matching_length) do |length|
        expected_result("%d characters" % length) { |r| r.length == length }
      end

      chain(:matching_params) do |params|
        expected_result("with params %p" % [params]) { |r| r.params == params }
      end

      failure_message do |scanner|
        if scanned = scanner.public_send(method_name, pattern, options = {})
          message  = result_expectations.inject(nil) { |m,e| m || e.call(scanned) }
        end
        message || "expected %p to %s %p" % [ scanner, method_name, pattern ]
      end

      failure_message_when_negated do |scanner|
        "expected %p not to %s %p" % [ scanner, method_name, pattern ]
      end
    end
  end
end
