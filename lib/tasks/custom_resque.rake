task "resque:setup" => :environment

# require 'resque/tasks'
# will give you the resque tasks

namespace :resque do
  task :levion_workers do
    require 'resque'
    $mutex = Mutex.new
    $working_mutex = Mutex.new
    $m3 = Mutex.new
    
    # preloading everything:
    $mutex.synchronize do
      # ActiveRecord::Base.descendants.each { |klass| klass.columns; klass.new if klass.respond_to?(first) }
      if defined?(Rails) && Rails.respond_to?(:application)
        # Rails 3
        Rails.application.eager_load!
      elsif defined?(Rails::Initializer)
        # Rails 2.3
        $rails_rake_task = false
        Rails::Initializer.run :load_application_classes
      end
    end

    module Resque
      class Worker
        @@semaphore = Mutex.new 
        
        
        # Given a string worker id, return a boolean indicating whether the
        # worker exists
        def self.exists?(worker_id)
          $m3.synchronize { redis.sismember(:workers, worker_id) }
        end
        
        # Returns an array of all worker objects currently processing
        # jobs.
        def self.working
          $working_mutex.synchronize do
            puts "LOCKED"
            names = all
            return [] unless names.any?

            names.map! { |name| "worker:#{name}" }

            reportedly_working = {}

            begin
              reportedly_working = redis.mapped_mget(*names).reject do |key, value|
                value.nil? || value.empty?
              end
            rescue Redis::Distributed::CannotDistribute
              names.each do |name|
                value = redis.get name
                reportedly_working[name] = value unless value.nil? || value.empty?
              end
            end

            reportedly_working.keys.map do |key|
              find key.sub("worker:", '')
            end.compact
          end
        end
        
        def to_s
          @to_s ||= "#{hostname}:#{Process.pid}:#{@queues.join(',')}:#{Thread.current.to_s.scan(/:0x(\w+)/).flatten.join}"
        end
        alias_method :id, :to_s

        # Looks for any workers which should be running on this server
        # and, if they're not, removes them from Redis.
        #
        # This is a form of garbage collection. If a server is killed by a
        # hard shutdown, power failure, or something else beyond our
        # control, the Resque workers will not die gracefully and therefore
        # will leave stale state information in Redis.
        #
        # By checking the current Redis state against the actual
        # environment, we can determine if Redis is old and clean it up a bit.
        def prune_dead_workers
          @@semaphore.synchronize do
            all_workers = Worker.all
            known_workers = worker_pids unless all_workers.empty?
            known_threads = worker_threads unless all_workers.empty?

            all_workers.each do |worker|
              host, pid, queues, thread = worker.id.split(':')
              next unless host == hostname
              next if known_workers.include?(pid)
              next if known_threads.include?(thread)
              log! "Pruning dead worker: #{worker}"
              worker.unregister_worker
            end
          end
        end

        def worker_threads
          resque_threads = Thread.list.select { |v| v[:resque] == true }
          resque_threads.map { |v| v.to_s.scan(/:0x(\w+)/).flatten.join }
        end

        # Registers ourself as a worker. Useful when entering the worker
        # lifecycle on startup.
        def register_worker
          redis.sadd(:workers, self)
          started!
        end

      end
    end
    
    threads = []
    workers = []
    
    ENV['COUNT'].to_i.times do
      threads << Thread.new do |thread|
        Thread.current[:resque] = true
        queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

        begin
          worker = Resque::Worker.new(*queues)
          worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
          worker.very_verbose = ENV['VVERBOSE']
        rescue Resque::NoQueueError
          abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
        end
        workers << worker
        worker.work(ENV['INTERVAL'] || 5) # interval, will block
      end
      sleep 1
    end
    
    $mutex.synchronize do
      threads.each { |thread| thread.run }
    end
        
    ACTIONABLE = [ "quit", "die" ]
    puts "Levion welcomes the Worker Starter Representative."
    puts "Threads currently running include #{threads.map { |v| v.to_s.scan(/:0x(\w+)/).flatten}.join(", ")}"
    puts "Remember to type QUIT at any time to finish jobs, or DIE to force termination immediately."
    puts ""
    puts "Thanks for using Levion."
    action = ""
    while not ACTIONABLE.include?(action.downcase.strip)
      print "> "
      action = STDIN.gets
    end
    
    action = action.downcase.strip
    
    if action == "quit"
      workers.each { |worker| worker.shutdown }
      while workers.detect { |w| w.working? }
        puts "--- JOBS STILL RUNNING -- PLEASE WAIT --"
        sleep 5
      end
      while threads.detect { |w| w.alive? }
        puts "--- THREADS STILL ALIVE -- PLEASE WAIT --"
        sleep 5
      end
      
    else
      workers.each { |worker| worker.shutdown }
      threads.each { |thread| thread.kill }
      sleep 5
    end    
  end
end