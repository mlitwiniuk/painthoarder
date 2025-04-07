class UsernameValidator < ActiveModel::EachValidator
  VALID_NAME_REGEX = /^[-\w._]+$/i # /([a-zA-Z0-9](_|-| )[a-zA-Z0-9])*/i
  # VALID_NAME_REGEX = /^[a-z][a-z0-9_.]*$/
  def validate_each(record, attribute, value)
    return if VALID_NAME_REGEX.match?(value)

    record.errors.add attribute,
      (options[:message] || "should only contain letters, numbers, underscore, hyphen")
  end
end
