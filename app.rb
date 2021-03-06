lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sinatra/base"
require "slim"
require "calc_bpm"

class App < Sinatra::Base

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    Slim::Engine.default_options[:pretty] = true
  end

  get "/" do
    slim :index
  end

  post "/" do
    @result = true
    @top_10 = main(params[:file])
    slim :index
  end
end
