module GModule

    def db_connect()
        db = SQLite3::Database.new("db/database.db")
        return db
    end

    def urmom(post_id)
        db = db_connect()
        parent_post = db.execute('SELECT * FROM Posts WHERE id IS ?', [post_id])
        return parent_post
    end

    def create_post(user_id)
        db = db_connect


end




