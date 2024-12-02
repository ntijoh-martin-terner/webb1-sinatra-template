# frozen_string_literal: true

# https://github.com/sinatra/sinatra-recipes/blob/main/asset_management/sinatra_assetpack.md

require APP_PATH

class Home < App
  set :environment, Sinatra::Base.environment # Explicitly set environment

  get '/' do
    erb :home
  end
end
