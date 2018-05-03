require_relative './module.rb'	
include GModule

class App < Sinatra::Base

	set :server, 'thin'
	set :sockets, []
	enable :sessions

	get '/' do
		slim :index
	end

	get '/foo' do
		return 'bar'
	end

	get '/register' do
		slim :register
	end

	get '/login' do
		slim :login
	end

	post '/register_user' do
		username = params[:username]
		password = params[:password]

		register(username,password)

		redirect('/')
	end

	post '/login_user' do

		db = SQLite3::Database.new("db/database.db")

		username = params[:username]
		password = params[:password]

		user_info = login_verify(username,password)

		if user_info[2] != nil
			user_info[2] = BCrypt::Password.new(user_info[2])
		else
			user_info[2] = ""
		end

		if username == user_info[1] && user_info[2] == password
			# Login successful
			session[:id] = user_info[0]
			session[:username] = username
			redirect('/profile/' + session[:id].to_s)
		else
			redirect('/error')
		end

	end

	post '/accept_friend' do
		id = params[:table_id].to_i
		accept_friend(id)

		redirect('/profile/' + session[:id].to_s)
	end

	post '/decline_friend' do
		id = params[:table_id].to_i
		decline_friend(id)

		redirect('/profile/' + session[:id].to_s)
	end
 
	get '/profile/:id' do

		id = params[:id].to_i

		if id != session[:id]
			redirect('/error')
		end

		session[:id] = id

		result = list_friends(id)

		slim(:menu, locals:{notes:result, id:id, i:0})  
	end

	post '/friend_request' do

		db = SQLite3::Database.new("db/database.db")

		User_sender = session[:id]
		User_reciever = params[:request_user]

		User_reciever_compare = User_reciever.to_i

		if User_reciever_compare.to_s != User_reciever.to_s
			redirect('/error')
		end

		User_sender = User_sender.to_i
		User_reciever = User_reciever.to_i

		# 0 = Pending, 1 = Accepted, 2 = Denied, 3 = Blocked
		
		request_sent = friend_request(user_sender,user_reciever)

		if request_sent == true
			redirect('/profile/' + session[:id].to_s)
		elsif request_sent == false
			redirect('/error')
		end

	end

	get '/forum' do
		posts =	forum_load()

		slim(:forum,locals:{posts:posts})
	end

	get '/post/:id' do
		post_id = params[:id].to_i
		posts = post_and_comments(post_id)
			
		slim(:post, locals:{parent_post:posts[0], child_posts:posts[1]})
	end

	post '/create_post' do

		user_id = session[:id]
		title = params[:create_post_title]
		content = params[:create_post_content]
		is_comment = params[:is_comment].to_i


		if user_id == nil
			redirect('/error')
		else
			if is_comment == 0
				create_post(title,content,user_id)
			else
				parent_id = params[:parent_id]
				create_comment(title,content,user_id,parent_id)
			end
			redirect('/forum')
		end

	end

	get '/error' do
		slim :error
	end

	#	Websocket application - Generic Chatroom

	
	get '/chatroom' do
		db = db_connect()

		if !request.websocket?
			slim :room_1
		else
			request.websocket do |ws|
				ws.onopen do
					ws.send("Hello World!")
					settings.sockets << ws
				end
				ws.onmessage do |msg|
					EM.next_tick do
						settings.sockets.each do |s| 
							s.send("#{session[:username].to_s}" + ": " + msg)
						end
					end
				end
				ws.onclose do
					warn("websocket closed")
					settings.sockets.delete(ws)
				end
			end
		end
	end

end
