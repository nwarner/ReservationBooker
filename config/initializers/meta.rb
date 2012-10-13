module ActiveRecord::ConnectionAdapters
  class JdbcAdapter < AbstractAdapter
    def explain(query, *binds)
      ActiveRecord::Base.connection.execute("EXPLAIN #{query}", 'EXPLAIN', binds)
    end
  end
end