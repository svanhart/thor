class Thor
  module LineEditor
    class Readline < Basic
      def self.available?
        begin
          require "readline"
        rescue LoadError
        end

        Object.const_defined?(:Readline)
      end

      def readline
        if echo?
          ::Readline.completion_append_character = nil
          # rb-readline does not allow Readline.completion_proc= to receive nil.
          if complete = completion_proc
            ::Readline.completion_proc = complete
          end
          ::Readline.readline(prompt, add_to_history?)
        else
          super
        end
      end

    private

      def add_to_history?
        options.fetch(:add_to_history, true)
      end

      def completion_proc
        if use_path_completion?
          proc { |text| PathCompletion.new(text, options[:additional_paths]).matches }
        elsif completion_options.any?
          proc do |text|
            completion_options.select { |option| option.start_with?(text) }
          end
        end
      end

      def completion_options
        options.fetch(:limited_to, [])
      end

      def use_path_completion?
        options.fetch(:path, false)
      end
        
      class PathCompletion
        attr_reader :text
        private :text

        def initialize(text, additional_paths)
          @text = text
          @additional_paths = additional_paths
        end

        def matches
          matches = Array.new
          matches << relative_matches
          @additional_paths.each { |path| matches << relative_matches(path)} unless @additional_paths.nil?
          
          matches.flatten
        end

      private

        def relative_matches(filepath = nil)
          absolute_matches(filepath).map { |path| path.sub(base_path(filepath), "") }
        end

        def absolute_matches(filepath)
          Dir[glob_pattern(filepath)].map do |path|
            if File.directory?(path)
              "#{path}/"
            else
              path
            end
          end
        end

        def glob_pattern(filepath)
          "#{base_path(filepath)}#{text}*"
        end

        def base_path(filepath = nil)
          (filepath.nil? || !File.exists?(filepath)) ? "#{Dir.pwd}/" : "#{filepath}/"
        end
      end
    end
  end
end
