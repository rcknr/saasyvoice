class MyFormBuilder < ActionView::Helpers::FormBuilder
  helpers = field_helpers + 
            %w{date_select datetime_select time_select} +
            %w{collection_select select country_select time_zone_select} -
            %w{hidden_field label fields_for submit} #Not decorated

  helpers.each do |name|
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}
      label = label(field, options[:label])
      error_text = ""
      object = @template.instance_variable_get("@#{@object_name}")
      unless object.nil? || options[:hide_errors]
        errors = object.errors.on(field.to_sym)
        if errors
          error_text = "<span class=\"error\">#{errors.is_a?(Array) ? errors.first : errors}</span>"
        end
      end
      @template.content_tag(:p, label + super + error_text)
    end
  end
  
#  def label(method, text=nil, options={})
#    text = text || method.to_s.humanize
#    
#    object = @template.instance_variable_get("@#{@object_name}")
#    unless object.nil? || options[:hide_errors]
#      errors = object.errors.on(method.to_sym)
#      puts("#{errors}")
#      if errors
#        text += " <span class=\"error\">#{errors.is_a?(Array) ? errors.first : errors}</span>"
#      end
#    end
#    text += "#{options[:additional_text]}" if options[:additional_text]
#    label = super(method, text, options)
#  end
end

