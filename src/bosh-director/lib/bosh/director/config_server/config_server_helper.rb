module Bosh::Director::ConfigServer
  module ConfigServerHelper

    # Checks if string starts with '((' and ends with '))'
    # @param [String] value string to be checked
    # @return [Boolean] true is it starts with '((' and ends with '))'
    def is_placeholder?(value)
      value.to_s.match(/^\(\(.*\)\)$/)
    end

    # @param [String] placeholder
    # @return [String] placeholder name stripped from starting and ending brackets
    # @raise [Error] if name does not meet specs
    def extract_placeholder_name(placeholder)
      name = placeholder.to_s.gsub(/(^\(\(|\)\)$)/, '')
      validate_placeholder_name(name)
      process_name!(name)
    end

    # @param [String] name
    # @param [String] director_name
    # @param [String] deployment_name
    # @return [String] name prepended with /:director_name/:deployment_name if name is not absolute
    def add_prefix_if_not_absolute(name, director_name, deployment_name)
      return name if name.start_with?('/')
      return "/#{director_name}/#{deployment_name}/#{name}"
    end

    # These are the variable names in the variables section of the manifest
    # @param [String] name the variable name
    # @raise [Error] if name does not meet variable name specs
    def validate_variable_name(name)
      unless /^[a-zA-Z0-9_\-\/]+$/ =~ name
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Variable name '#{name}' must only contain alphanumeric, underscores, dashes, or forward slash characters"
      end

      if name.end_with? '/'
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Variable name '#{name}' must not end with a forward slash"
      end

      if /\/\// =~ name
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Variable name '#{name}' must not contain two consecutive forward slashes"
      end
    end

    # @param [Array] placeholders list of potential absolute placeholders
    # @raise [Error] if a placeholder is not absolute
    def validate_absolute_names(placeholders)
      non_absolute_names = placeholders.inject([]) do |memo, placeholder|
        name = extract_placeholder_name(placeholder)
        memo << name unless name.start_with?('/')
        memo
      end

      quoted_non_absolute_names = non_absolute_names.map {|item| "'#{item}'"}
      raise Bosh::Director::ConfigServerIncorrectNameSyntax, 'Names must be absolute path: ' + quoted_non_absolute_names.join(', ') unless quoted_non_absolute_names.empty?
    end

    # local utility methods

    def validate_placeholder_name(name)
      # Allowing exclamation mark for spiff
      unless /^[a-zA-Z0-9_\-\.!\/]+$/ =~ name
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' must only contain alphanumeric, underscores, dashes, or forward slash characters"
      end

      if name.end_with? '/'
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' must not end with a forward slash"
      end

      if /\/\// =~ name
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' must not contain two consecutive forward slashes"
      end

      validate_name_dot_syntax(name)
      validate_bang_character(name)
    end

    def validate_bang_character(name)
      bang_count = name.scan(/!/).count
      if bang_count > 1
        raise Bosh::Director::ConfigServerIncorrectNameSyntax, bang_error_msg(name)
      elsif bang_count == 1
        unless name.start_with?('!') && name.size != 1
          raise Bosh::Director::ConfigServerIncorrectNameSyntax, bang_error_msg(name)
        end
      end
    end

    def validate_name_dot_syntax(name)
      if name.include? '/'
        slug_before_last_slash = name[/.*\//]
        if slug_before_last_slash.include? '.'
          raise Bosh::Director::ConfigServerIncorrectNameSyntax,
                "Placeholder name '#{name}' syntax error: Must not contain dots before the last slash"
        end
      end

      slug_after_last_slash = name[/[^\/]+$/]

      if slug_after_last_slash.start_with? '.'
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' syntax error: Must not have segment starting with a dot"
      end

      if slug_after_last_slash.end_with? '.'
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' syntax error: Must not end name with a dot"
      end

      if /\.\./ =~ slug_after_last_slash
        raise Bosh::Director::ConfigServerIncorrectNameSyntax,
              "Placeholder name '#{name}' syntax error: Must not contain consecutive dots"
      end
    end

    def bang_error_msg(name)
      "Placeholder name '#{name}' contains invalid character '!'. If it is included for spiff, " +
        'it should only be at the beginning of the name. Note: it will not be considered a part of the name'
    end

    def process_name!(name)
      name.gsub(/^!/, '') # remove ! because of spiff
    end
  end
end