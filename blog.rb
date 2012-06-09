# -*- coding: utf-8 -*-

require 'mongo'
require 'erubis'
require 'date'
require 'uuidtools'
require 'sinatra/base'

class Blog < Sinatra::Base
  @@config = c = YAML.load(File.read('config.yaml'))
  @@db = Mongo::Connection.new(c['mongo']['host'], c['mongo']['port']).db(c['mongo']['db'])
  @@db.authenticate(c['mongo']['user'], c['mongo']['pass'])
  @@coll = @@db.collection(c['mongo']['coll']) 
  @@footer = File.read('views/footer.txt')

  get '/' do
    redirect '/text/index.html'
  end

  get '/index.html' do
    redirect '/text/index.html'
  end

  get '/echo' do
    request.inspect
  end

  get '/feed.atom' do
    @posts = get_posts('text', 0)
    @blog = @@config['blog']
    content_type 'application/atom+xml'
    erb :atom, :layout => false
  end

  get '/sitemap.xml' do
    @posts = @@coll.find({:reblogged_root_url=>nil})
    @blog = @@config['blog']
    content_type 'application/xml'
    erb :sitemaps, :layout => false
  end

  get '/text/index.html' do
    @agent = request.user_agent
    @posts = get_posts('text', 0)
    @blog = @@config['blog']
    @footer = @@footer
    erb :text
  end

  get '/:type/id/:id.html' do
    @agent = request.user_agent
    @posts = get_post(params[:type], params[:id])
    @blog = @@config['blog']
    @footer = @@footer
    erb params[:type].intern
  end

  get '/:type/id/:id.json' do
    @posts = get_post(params[:type], params[:id])
    content_type 'application/javascript; charset=utf-8'
    erb :json, :layout => false
  end

  get '/text/page/:page.html' do
    @agent = request.user_agent
    @posts = get_posts('text', params[:page])
    @blog = @@config['blog']
    @footer = @@footer
    erb :text
  end

  def get_posts(type, offset)
    limit = @@config['blog']['limit']
    @@coll.find({:reblogged_root_url=>nil, :type=>type}, {:sort=>[:timestamp ,:desc], :limit=>limit, :skip=>offset.to_i*limit})
  end

  def get_post(type, id)
    @@coll.find({:id=>id.to_i, :type=>type})
  end

end
