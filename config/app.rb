# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/url_for'
require 'better_errors'
require 'rdiscount'
require 'erb'

class App < Sinatra::Base
  configure do
    set :root, APP_ROOT
    set :views, VIEWS_PATH
    set :components, COMPONENTS_PATH
    set :public_folder, PUBLIC_PATH
  end

  # Just in development!
  configure :development do
    use BetterErrors::Middleware
    # you need to set the application root in order to abbreviate filenames
    # within the application:
    BetterErrors.application_root = APP_ROOT
  end

  helpers Sinatra::UrlForHelper

  # Override the `erb` method to include custom layout lookup
  def erb(template, options = {}, locals = {})
    # Find the layout file, if any

    view_path = File.join(settings.views, "#{template}.erb")

    layout_file = find_layout_file(view_path)

    # Include the layout in options if it exists
    options[:layout] = layout_file ? File.read(layout_file) : false unless options[:find_layout] == false

    # Call the original `erb` method with updated options
    super(template, options, locals)
  end

  private

  # Finds a `layout.erb` file starting from the current directory up to `/routes/`
  def find_layout_file(start_path)
    current_path = File.dirname(start_path)

    until [ROUTES_PATH, '/'].include?(current_path)
      layout_path = File.join(current_path, 'layout.erb')

      return layout_path if File.exist?(layout_path)

      current_path = File.dirname(current_path) # Move up one level
    end

    nil # No layout found
  end

  # Helper for dynamically loading components
  helpers do
    # Dynamically load and define methods for components
    Dir.glob(File.join(settings.components, '/*/*.rb')).each do |component|
      # Require the component file
      require component

      # Get the class name by capitalizing the file's base name
      class_name = File.basename(component, '.rb').split('_').map(&:capitalize).join

      # Dynamically define a helper method for the component
      define_method(class_name.to_sym) do |*args|
        # Instantiate the component with provided arguments
        component_class = Object.const_get(class_name)
        component_instance = component_class.new(*args)

        # Render the component's ERB template
        component_instance.render
      end
    end
  end
end