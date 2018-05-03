module GModule

    def db_connect()
        db = SQLite3::Database.new("db/database.db")
        return db
    end

    def register(username,password)
        db = db_connect()
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO Users(username,password,state) VALUES(?,?,0)", [username,password_digest])
    end

    def login_verify(username,password)
        db = db_connect()
        id, username_verify, password_verify, state = db.execute("SELECT * FROM Users WHERE username = '#{username}'")[0]
        
        return [id,username_verify,password_verify,state] 
    end

    def accept_friend(id)
        db = db_connect()
		db.execute("UPDATE Relations SET Relation_State = 1 WHERE ID = ?", [id])
    end

    def decline_friend(id)
        db = db_connect()
        db.execute("DELETE FROM Relations WHERE ID = ?", [id])
    end

    def list_friends(id)
        db = db_connect()
        return db.execute("SELECT * FROM Relations WHERE (User_1 = #{session[:id]} OR User_2 = #{session[:id]})")
    end

    def friend_request(user_sender,user_reciever)
        db = db_connect()
        user_reciever_id_instance = db.execute("SELECT * FROM Users WHERE id = ?", [user_reciever])

		if user_reciever_id_instance.empty? == false # Checks if the user recipent is non-existant

			if user_sender < user_reciever
				db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [user_sender, user_reciever, user_sender])
			elsif user_reciever < user_sender
				db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [user_reciever, user_sender, user_sender])
			else
				return false
            end
            return true
		else
			return false
		end
    end

    def forum_load()
        db = db_connect()
        db.execute('SELECT * FROM Posts WHERE parent_id IS NULL')
    end

    def post_and_comments(post_id)
        db = db_connect()
        parent_post = db.execute('SELECT * FROM Posts WHERE id IS ?', [post_id])
        child_posts = db.execute('SELECT * FROM Posts WHERE parent_id IS ?', [post_id])
	
        return [parent_post, child_posts]
    end

    def create_post(title,content,user_id)
        db = db_connect()
        db.execute('INSERT INTO Posts(title,content,user_id,parent_id,upvotes,downvotes) VALUES(?,?,?,NULL,0,0)', [title,content,user_id])
    end

    def create_comment(title,content,user_id,parent_id)
        db = db_connect()
        db.execute('INSERT INTO Posts(title,content,user_id,parent_id,upvotes,downvotes) VALUES(?,?,?,?,0,0)', [title,content,user_id,parent_id])
    end
end




