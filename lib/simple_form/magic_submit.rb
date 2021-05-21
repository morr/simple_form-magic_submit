require 'simple_form/magic_submit/version'

module SimpleForm
  module MagicSubmit
    def magic_submit_button(*args, &block)
      options = args.extract_options!
      options[:data] ||= {}
      options[:data][:disable_with] ||= translate_key(:disable_with)
      options[:class] =
        if options.delete(:overwrite_default_classes)
          [options[:class]]
        else
          [main_class(options), 'btn-submit', options[:class]].compact
        end
      options[:id] ||= "submit_#{object_scope}"
      options[:autocomplete] ||= :off
      options[:tabindex] ||= 0

      args << options

      if cancel = options.delete(:cancel)
        I18n.t(
          'simple_form.magic_submit.cancel.format',
          submit_button: submit(submit_title(options), *args, &block).html_safe,
          cancel_link: template.link_to(I18n.t('simple_form.magic_submit.cancel.cancel').html_safe, cancel)
        )
      else
        submit(submit_title(options), *args, &block)
      end.html_safe
    end

    private

    def submit_title(options, key = nil)
      if title = options.delete(:submit_title)
        title
      else
        translate_key(key)
      end
    end

    def bound_to_model?
      return true if devise_controller?

      #  if its a string means that its bound to a model.. but if its a symbol its not...
      object_name.is_a?(String) # || self.object.present?
    end

    def devise_controller?
      template.controller.respond_to?(:devise_controller?) && template.controller.devise_controller?
    end

    def got_errors?
      object.errors.count > 0 || template.flash['alert'].present?
    end

    def main_class(options = {})
      options.fetch(:destructive, false) ? 'btn-destructive' : 'btn-primary'
    end

    def controller_scope
      template.controller.params[:controller].gsub('/', '.')
    end

    def object_scope
      # returns empty string if no model is found to prevent exception
      return '' unless bound_to_model?

      object.class.model_name.i18n_key.to_s
    end

    def translated_model_name
      return object.class.model_name.human.titlecase if bound_to_model?

      I18n.t("activerecord.models.#{object_name.to_s.singularize}.one", default: object_name.to_s.humanize)
    end

    def translate_key(key = nil)
      if bound_to_model?
        key ||= got_errors? ? :retry : :submit

        I18n.t(
          "simple_form.magic_submit.#{controller_scope}.#{object_scope}.#{lookup_action}.#{key}",
          default: [
            :"simple_form.magic_submit.#{controller_scope}.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.#{object_scope}.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.#{object_scope}.#{key}",
            :"simple_form.magic_submit.default.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.default.#{key}",
            :"helpers.submit.#{lookup_action}"
          ],
          model: translated_model_name
        ).html_safe
      else
        # we have no model errors... so we test if the post is get or already posted
        key ||= template.request.get? ? :submit : :retry
        I18n.t(
          "simple_form.magic_submit.#{controller_scope}.#{object_scope}.#{lookup_action}.#{key}",
          default: [
            :"simple_form.magic_submit.#{controller_scope}.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.default.#{lookup_action}.#{key}",
            :"simple_form.magic_submit.default.#{key}",
            :"helpers.submit.#{lookup_action}"
          ],
          model: translated_model_name
        ).html_safe
      end
    end
  end
end

SimpleForm::FormBuilder.include SimpleForm::MagicSubmit
I18n.load_path += Dir.glob(File.join(File.dirname(__FILE__), '..', '..', 'locales', '*.{rb,yml}'))
