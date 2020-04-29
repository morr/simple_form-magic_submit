require "simple_form/magic_submit/version"

module SimpleForm
  module MagicSubmit

    def magic_submit_button(*args, &block)
      options = args.extract_options!
      options[:data] ||= {}
      options[:data][:disable_with] ||= translate_key(:disable_with)
      options[:class] = if options.delete(:overwrite_default_classes)
                          [options[:class]]
                        else
                          [main_class(options), 'btn-submit', options[:class]].compact
                        end
      options[:id] ||= "submit_#{object_scope}"
      options[:autocomplete] ||= :off
      args << options
      if cancel = options.delete(:cancel)
        I18n.t("simple_form.magic_submit.cancel.format",
          submit_button: submit(submit_title(options), *args, &block).html_safe,
          cancel_link: template.link_to(I18n.t('simple_form.magic_submit.cancel.cancel').html_safe, cancel)
        )
      else
        submit(submit_title(options), *args, &block)
      end.html_safe
    end

  private

    def submit_title(options, key=nil)
      if title = options.delete(:submit_title)
        title
      else
        translate_key(key)
      end
    end

    def bound_to_model?
      #  if its a string means that its bound to a model.. but if its a symbol its not...
      self.object_name.is_a?(String)# || self.object.present?
    end

    def main_class(options = {})
      options.fetch(:destructive, false) ? 'btn-destructive' : 'btn-primary'
    end

    def controller_scope
      # falls to default if the model isn't tied to a model
      return "default" unless bound_to_model?

      template.controller.params[:controller].gsub('/', '.')
    end

    def object_scope
      # returns empty string if no model is found to prevent exception
      return "" unless bound_to_model?

      self.object.class.model_name.i18n_key.to_s
    end

    def translate_key(key = nil)

      if bound_to_model?
        key ||= self.object.errors.count > 0 ? :retry : :submit

        I18n.t("simple_form.magic_submit.#{controller_scope}.#{object_scope}.#{lookup_action}.#{key}",
          default: [
            :"simple_form.magic_submit.#{controller_scope}.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.default.#{lookup_action}.#{key}",
            :"helpers.submit.#{lookup_action}"
          ],
          model: self.object.class.model_name.human.titlecase
        ).html_safe
      else
        # we have no model errors... so we test if the post is get or already posted
        key ||= template.request.get? ? :submit : :retry
        I18n.t("simple_form.magic_submit.#{controller_scope}.#{object_scope}.#{lookup_action}.#{key}",
          default: [
            :"simple_form.magic_submit.#{controller_scope}.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.default.#{lookup_action}.#{key}",
            :"helpers.submit.#{lookup_action}"
        ]).html_safe
      end
    end

  end
end

SimpleForm::FormBuilder.send :include, SimpleForm::MagicSubmit
I18n.load_path += Dir.glob(File.join(File.dirname(__FILE__), '..', '..', 'locales', '*.{rb,yml}'))
