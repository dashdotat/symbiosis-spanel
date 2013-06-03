require 'rpam'
require 'sinatra/base'
require 'symbiosis'
require 'symbiosis/domains'
require 'symbiosis/domain/dns'
require 'symbiosis/domain/mailbox'

include Rpam

module Symbiosis
	class Domain
		def writable?
			File.writable?(self.directory)
		end

		class Mailbox
			def admin?
				if self.exists?
					param = get_param("admin", self.directory)
				else
					param = false
				end
				param
			end

			def admin=(value)
				raise ArgumentError unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
				if self.exists?
					set_param("admin", true, self.directory)
				end
			end
		end
	end

	module SPanel
		class Auth
			def self.authenticate(username, password)
				ret = nil
				if /@/ =~ username
					user = Symbiosis::Domains.find_mailbox(username)
					if user.admin? && user.login(password)
						ret = [user.local_part, user.domain.name]
					end
				else
					ret = [username,"PAM"] if authpam(username, password)
				end
				ret
			end
		end

		class App < Sinatra::Base
			set :sessions, true
			set :public_folder, File.dirname(__FILE__) + '/public'
			before do
				redirect '/login' if session[:logged_in] != true && request.path_info != '/login'
			end

			get '/' do
				@domains = Symbiosis::Domains.all
				erb :index
			end

			get '/login' do
				erb :login
			end

			post '/login' do
				username = params[:username]
				password = params[:password]
				session[:logged_in] = nil
				session[:username] = nil
				if Symbiosis::SPanel::Auth.authenticate(username, password)
					session[:logged_in] = true
					session[:username] = username
					redirect '/'
				else
					erb :login
				end
			end

			get '/logout' do
				session[:logged_in] = nil
				session[:username] = nil
				redirect '/login'
			end

			post '/domains/create' do
				@domain = Symbiosis::Domain.new(params[:domain])
				redirect "/domains/#{@domain.name}" if @domain.exists?
				@domain.create
				redirect "/domains/#{@domain.name}"
			end

			get '/domains/:domain' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				erb :domain_main
			end

			post '/domains/:domain' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				puts params.inspect
				antispam = params[:antispam].nil? ? false : true
				@domain.use_bytemark_antispam = antispam
				redirect "/domains/#{@domain.name}"
			end

			get '/domains/:domain/mailboxes/create' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				erb :mailbox_create
			end

			post '/domains/:domain/mailboxes/create' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				@localpart = params[:localpart]
				mailbox = Symbiosis::Domain::Mailbox.new(@localpart, @domain)
				redirect "/domains/#{@domain.name}" if mailbox.exists?
				mailbox.create
				redirect "/domains/#{@domain.name}"
			end

			get '/domains/:domain/mailboxes/:local_part/reset_password' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				@mailbox = @domain.find_mailbox(params[:local_part])
				redirect '/' unless @mailbox.exists?
				erb :mailbox_reset
			end

			post '/domains/:domain/mailboxes/:local_part/reset_password' do
				@domain = Symbiosis::Domains.find(params[:domain])
				redirect '/' if @domain.nil?
				@mailbox = @domain.find_mailbox(params[:local_part])
				redirect '/' unless @mailbox.exists?
				if params[:password] != params[:password_confirm]
					erb :mailbox_reset
				else
					@mailbox.password = params[:password]
					redirect "/domains/#{@domain.name}"	
				end
			end
		end
	end
end
