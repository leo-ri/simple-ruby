require 'sinatra'
require 'json'
require 'mongo'
require 'uri'

get '/env' do
  ENV['VCAP_SERVICES']
end

get '/rack/env' do
  ENV['RACK_ENV']
end

get '/' do
  'hello from sinatra'
end

get '/ping' do
  'works'
end

get '/crash' do
  Process.kill('KILL', Process.pid)
end

put '/service/mongo/:key' do
  client = load_mongo
  value = request.env['rack.input'].read
  if client[:data_values].find('_id' => params[:key]).to_a.empty?
    client[:data_values].insert_one( { '_id' => params[:key], 'data_value' => value } )
  else
    client[:data_values].find('_id' => params[:key]).replace_one( {'data_value' => value } )
  end
  'success'
end

delete '/service/mongo/:key' do
  client = load_mongo
  if client[:data_values].find('_id' => params[:key]).to_a.empty?
    'document is not found'
  else
    client[:data_values].find('_id' => params[:key]).delete_one
  end
  'deleted success'
end

get '/service/mongo/:key' do
  client = load_mongo
  client[:data_values].find('_id' => params[:key]).to_a.first['data_value']
end

not_found do
  'This is nowhere to be found.'
end

error do
  error = env['sinatra.error']
<<TEXT
#{error.inspect}

Backtrace:
  #{error.backtrace.join("\n  ")}
TEXT
end

def load_mongo
  services = JSON.parse(ENV["VCAP_SERVICES"])
  credentials = services["mongodb-atlas-aws"][0]["credentials"]
  base = credentials["uri"]
  uri = "mongodb+srv://"+credentials["username"]+":"+credentials["password"]+"@"+base[14..credentials["uri"].length]+"/test"
  client = Mongo::Client.new(uri)
end
