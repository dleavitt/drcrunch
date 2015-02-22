RACK_ENV = ENV['RACK_ENV'] || 'development'

require 'rubygems'
require 'bundler'
Bundler.require :default, RACK_ENV
$LOAD_PATH << File.expand_path('../lib', __FILE__)

Dotenv.load
Mongoid.load!("config/mongoid.yml")

# require services here
# Dir['./lib/helpers/**/*.rb'].each(&method(:require))

::Sass::Script::Number.precision = [8, ::Sass::Script::Number.precision].max

class DrCrunch < Sinatra::Base
  set :logger, Logger.new(STDOUT)
  set :protection, except: :frame_options
  mime_type :woff2, 'application/font-woff2'
  enable :logging
  enable :method_override
  enable :static

  # dev-inappropriate settings are automatically ignored :/
  set :assets_precompile, %w(app.js app.css *.png *.jpg *.svg *.eot *.ttf *.woff *.woff2)
  set :assets_prefix, %w(assets vendor/assets)
  set :assets_css_compressor, :sass
  set :assets_js_compressor, Uglifier.new(mangle: false)
  # set :assets_host, ENV['CDN_HOST']
  # set :assets_protocol, :https

  register Sinatra::Namespace
  use Rack::PostBodyContentTypeParser

  configure :development do
    set :assets_debug, true

    register Sinatra::Reloader
    Dir['./lib/**/*.rb'].each(&method(:also_reload))

    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__

    use Rack::Cache
    use Rack::LiveReload
  end

  configure :production do
    set :static_cache_control, [:public, max_age: 1.year]

    # use Rack::SSL

    # set :memcached, Dalli::Client.new(nil,
    #   failover: true,
    #   socket_timeout: 1.5,
    #   socket_failure_delay: 0.2,
    #   value_max_bytes: 10485760,
    #   pool_size: 12
    # )
    # use Rack::Cache, metastore: settings.memcached, entitystore: settings.memcached

    # Raven.configure { |c| c.dsn = ENV['RAVEN_DSN'] }
    # use Raven::Rack
  end

  register Sinatra::AssetPipeline
  # AutoprefixerRails.install(settings.sprockets)

  # before do
  #   cache_control :public, max_age: 0
  # end

  get '/' do
    erb :app
  end

  post '/api/images' do
    
    image = ImageUpload.new
    image.upload_from_attachment(params['file'])
    image.save!

    json image
  end

  put '/api/images/:id/crunch' do

    image = ImageUpload.find_by(uuid: params[:id])
    new_image = image.make_child
    new_image.compression_settings = params[:compression]

    compression = params[:compression].deep_dup

    compression.each do |worker, worker_params|
      compression[worker] = false unless worker_params.delete('enabled')
    end

    if (pngquant = compression[:pngquant])
      if (min = pngquant.delete('quality_min')) && (max = pngquant.delete('quality_max'))
        pngquant['quality'] = (min.to_i..max.to_i)
        compression[:pngquant] = pngquant
      end
    end

    compression = compression.merge(
      allow_lossy: true,
      svgo: false,
      verbose: true
      # pngout: false,
    )

    image_optim = ImageOptim.new(compression)

    s3_obj = image.s3_object.get
    Tempfile.open(new_image.uuid) do |file|
      file.write(s3_obj.body.read)
      new_image.compression_time = Benchmark.measure { image_optim.optimize_image!(file) }.real
      new_image.upload_raw(file.open.read)
    end
    new_image.save!

    json new_image
  end
end

class ImageUpload
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uuid, type: String, default: -> { SecureRandom.hex(4) }
  field :content_type, type: String
  field :extension, type: String
  field :content_length, type: Integer
  field :compression_time, type: Float
  field :compression_settings, type: Hash
  
  field :parent_uuid, type: String

  def upload_from_attachment(file)
    self.extension = File.extname(file[:filename])
    self.content_type = file[:type]

    upload_raw(file[:tempfile].read)
  end

  def upload_raw(body)
    s3_object.put(
      acl: 'public-read',
      body: body,
      content_type: self.content_type
    )

    self.content_length = s3_object.content_length
  end

  def make_child
    self.class.new(
      content_type: content_type,
      extension: extension,
      parent_uuid: uuid
    )
  end

  def s3_key
    "uploads/" + self.uuid + self.extension
  end

  def public_url
    s3_object.public_url
  end

  def filtered_compression_settings
    compression_settings.andand.find_all { |_, v| v['enabled'] }.to_h
  end

  def to_json(args = {})
    { 
      id: uuid, 
      url: public_url,
      content_length: content_length,
      size: ActiveSupport::NumberHelper.number_to_human_size(content_length),
      compression_time: compression_time,
      compression_settings: filtered_compression_settings,
    }.to_json
  end

  def s3_object
    Aws::S3::Object.new(ENV['AWS_S3_BUCKET'], s3_key)
  end
end
# Dir['./lib/routes/**/*.rb'].each(&method(:require))
