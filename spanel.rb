require 'sinatra/base'
require './lib/spanel'

module Symbiosis
	module SPanel
		class App < Sinatra::Base
			set :sessions, true
			set :public_folder, File.dirname(__FILE__) + '/public'
			before do
				redirect '/login' if session[:logged_in] != true && request.path_info != '/login'
			end

			helpers do
				def check_domain_access(domain)
					if session[:user] && session[:user][1].downcase == domain.downcase
						check_domain = get_domain(domain)
					else
						redirect '/'
					end
					check_domain
				end

				def get_domain(domain)
					val = Symbiosis::Domains.find(domain)
					redirect '/' if val.nil?
					val
				end
			end

			get '/' do
				@domains = Symbiosis::Domain.new(session[:user][1]).to_a
				erb :index
			end

			get '/login' do
				erb :login
			end

			post '/login' do
				username = params[:username]
				password = params[:password]
				session[:logged_in] = nil
				session[:user] = nil
				auth = Symbiosis::SPanel::Auth.authenticate(username, password)
				if auth and auth.is_a?(Array)
					session[:logged_in] = true
					session[:user] = auth
					redirect "/domains/#{session[:user][1]}"
				else
					erb :login
				end
			end

			get '/logout' do
				session[:logged_in] = nil
				session[:username] = nil
				redirect '/login'
			end

#			post '/domains/create' do
#				redirect '/' unless session[:user][1] == "PAM"
#				@domain = Symbiosis::Domain.new(params[:domain])
#				redirect "/domains/#{@domain.name}" if @domain.exists?
#				@domain.create
#				redirect "/domains/#{@domain.name}"
#			end

			get '/domains/:domain' do
				@domain = check_domain_access(params[:domain])
				erb :domain_main
			end

			post '/domains/:domain' do
				@domain = check_domain_access(params[:domain])
				antispam = params[:antispam].nil? || !@domain.is_bytemark_content_dns? ? false : true
				@domain.use_bytemark_antispam = antispam
				redirect "/domains/#{@domain.name}"
			end

			get '/domains/:domain/mailboxes/create' do
				@domain = check_domain_access(params[:domain])
				erb :mailbox_create
			end

			post '/domains/:domain/mailboxes/create' do
				@domain = check_domain_access(params[:domain])
				@localpart = params[:localpart]
				mailbox = Symbiosis::Domain::Mailbox.new(@localpart, @domain)
				redirect "/domains/#{@domain.name}" if mailbox.exists?
				mailbox.create
				redirect "/domains/#{@domain.name}"
			end

			get '/domains/:domain/mailboxes/:local_part' do
				@domain = check_domain_access(params[:domain])
			end

			post '/domains/:domain/mailboxes/:local_part' do
				@domain = check_domain_access(params[:domain])
			end

			get '/domains/:domain/mailboxes/:local_part/reset_password' do
				@domain = check_domain_access(params[:domain])
				@mailbox = @domain.find_mailbox(params[:local_part])
				redirect '/' unless @mailbox.exists?
				erb :mailbox_reset
			end

			post '/domains/:domain/mailboxes/:local_part/reset_password' do
				@domain = check_domain_access(params[:domain])
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
