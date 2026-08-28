#!/usr/bin/env ruby
# Threading and Concurrency Demo in Ruby
# Run with: ruby threading_demo.rb

puts "=" * 60
puts "RUBY THREADING & CONCURRENCY DEMO"
puts "=" * 60

# ============================================================
# PART 1: Basic Thread Creation
# ============================================================

puts "\n📌 PART 1: Basic Thread Creation"
puts "-" * 40

# Create a simple thread
thread = Thread.new do
  puts "  Hello from thread! (Thread ID: #{Thread.current.object_id})"
end

puts "  Main thread continues... (Thread ID: #{Thread.current.object_id})"
thread.join  # Wait for thread to complete

# ============================================================
# PART 2: Single-Threaded Sum (Baseline)
# ============================================================

puts "\n📌 PART 2: Single-Threaded Sum (Baseline)"
puts "-" * 40

numbers = (1..1_000_000).to_a

start_time = Time.now
single_thread_sum = numbers.sum
end_time = Time.now

puts "  Numbers: 1 to 1,000,000"
puts "  Sum: #{single_thread_sum}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 3: Multi-Threaded Sum (WRONG WAY - Race Condition!)
# ============================================================

puts "\n📌 PART 3: Multi-Threaded Sum (WRONG WAY - Race Condition!)"
puts "-" * 40

shared_sum = 0  # Shared variable - DANGER!
thread_count = 4
chunk_size = numbers.length / thread_count

start_time = Time.now

threads = thread_count.times.map do |i|
  Thread.new do
    start_idx = i * chunk_size
    end_idx = (i == thread_count - 1) ? numbers.length : (i + 1) * chunk_size

    # Each thread adds to shared_sum - RACE CONDITION!
    (start_idx...end_idx).each do |idx|
      shared_sum += numbers[idx]  # NOT THREAD SAFE!
    end
  end
end

threads.each(&:join)
end_time = Time.now

puts "  ⚠️  This demonstrates a RACE CONDITION"
puts "  Expected: #{single_thread_sum}"
puts "  Got:      #{shared_sum}"
puts "  Correct?: #{shared_sum == single_thread_sum ? '✅ Yes (got lucky!)' : '❌ NO - Data corrupted!'}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 4: Multi-Threaded Sum (CORRECT - Using Mutex)
# ============================================================

puts "\n📌 PART 4: Multi-Threaded Sum (CORRECT - Using Mutex)"
puts "-" * 40

mutex = Mutex.new
mutex_sum = 0

start_time = Time.now

threads = thread_count.times.map do |i|
  Thread.new do
    start_idx = i * chunk_size
    end_idx = (i == thread_count - 1) ? numbers.length : (i + 1) * chunk_size

    local_sum = 0
    (start_idx...end_idx).each do |idx|
      local_sum += numbers[idx]  # Calculate locally first
    end

    # Only lock when updating shared variable
    mutex.synchronize do
      mutex_sum += local_sum
    end
  end
end

threads.each(&:join)
end_time = Time.now

puts "  Using Mutex for thread safety"
puts "  Expected: #{single_thread_sum}"
puts "  Got:      #{mutex_sum}"
puts "  Correct?: #{mutex_sum == single_thread_sum ? '✅ Yes' : '❌ No'}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 5: Multi-Threaded Sum (BEST - Thread-Local + Collect)
# ============================================================

puts "\n📌 PART 5: Multi-Threaded Sum (BEST - Thread-Local + Collect)"
puts "-" * 40

start_time = Time.now

threads = thread_count.times.map do |i|
  Thread.new do
    start_idx = i * chunk_size
    end_idx = (i == thread_count - 1) ? numbers.length : (i + 1) * chunk_size

    # Each thread returns its local sum - no shared state!
    local_sum = 0
    (start_idx...end_idx).each do |idx|
      local_sum += numbers[idx]
    end
    local_sum  # Return value from thread
  end
end

# Collect results from all threads and sum them
partial_sums = threads.map(&:value)  # .value waits and gets return value
best_sum = partial_sums.sum

end_time = Time.now

puts "  No shared state - each thread returns its sum"
puts "  Partial sums: #{partial_sums.inspect}"
puts "  Total: #{best_sum}"
puts "  Correct?: #{best_sum == single_thread_sum ? '✅ Yes' : '❌ No'}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 6: Using Queue for Thread Communication
# ============================================================

puts "\n📌 PART 6: Using Queue for Thread Communication"
puts "-" * 40

require 'thread'

queue = Queue.new
results = Queue.new

# Producer: Add work items to queue
numbers.each_slice(250_000) { |chunk| queue << chunk }

start_time = Time.now

# Consumer threads: Process work from queue
workers = 4.times.map do
  Thread.new do
    while !queue.empty?
      begin
        chunk = queue.pop(true)  # non-blocking pop
        results << chunk.sum
      rescue ThreadError
        # Queue empty, exit loop
        break
      end
    end
  end
end

workers.each(&:join)

# Collect results
queue_sum = 0
until results.empty?
  queue_sum += results.pop
end

end_time = Time.now

puts "  Producer-Consumer pattern with Queue"
puts "  Expected: #{single_thread_sum}"
puts "  Got:      #{queue_sum}"
puts "  Correct?: #{queue_sum == single_thread_sum ? '✅ Yes' : '❌ No'}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 7: Thread Pool Pattern
# ============================================================

puts "\n📌 PART 7: Thread Pool Pattern"
puts "-" * 40

class ThreadPool
  def initialize(size)
    @size = size
    @jobs = Queue.new
    @results = Queue.new
    @workers = []

    @size.times do
      @workers << Thread.new do
        loop do
          job = @jobs.pop
          break if job == :shutdown
          @results << job.call
        end
      end
    end
  end

  def schedule(&block)
    @jobs << block
  end

  def shutdown
    @size.times { @jobs << :shutdown }
    @workers.each(&:join)
  end

  def results
    result_array = []
    result_array << @results.pop until @results.empty?
    result_array
  end
end

pool = ThreadPool.new(4)

start_time = Time.now

# Schedule work
numbers.each_slice(250_000) do |chunk|
  pool.schedule { chunk.sum }
end

# Small delay to let jobs complete
sleep(0.1)

pool.shutdown
pool_sum = pool.results.sum

end_time = Time.now

puts "  Custom Thread Pool with 4 workers"
puts "  Expected: #{single_thread_sum}"
puts "  Got:      #{pool_sum}"
puts "  Correct?: #{pool_sum == single_thread_sum ? '✅ Yes' : '❌ No'}"
puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"

# ============================================================
# PART 8: Ruby's GIL (Global Interpreter Lock) Explained
# ============================================================

puts "\n📌 PART 8: Ruby's GIL Explained"
puts "-" * 40

puts <<~GIL
  🔒 Ruby has a Global Interpreter Lock (GIL/GVL)

  What it means:
  • Only ONE thread can execute Ruby code at a time
  • Threads still useful for I/O-bound tasks (waiting for API, DB, files)
  • NOT useful for CPU-bound parallel computation

  For TRUE parallelism in Ruby, use:
  • Ractors (Ruby 3.0+) - actor-based parallelism
  • Process.fork - separate processes
  • JRuby or TruffleRuby - no GIL

  When threads ARE useful:
  • Making multiple API calls simultaneously
  • Reading multiple files at once
  • Handling multiple web requests (Puma server)
  • Any I/O waiting scenario
GIL

# ============================================================
# PART 9: Practical Example - Parallel API Calls (Simulated)
# ============================================================

puts "\n📌 PART 9: Practical Example - Parallel API Calls"
puts "-" * 40

def fetch_api(endpoint)
  sleep(0.5)  # Simulate API latency
  "Data from #{endpoint}"
end

endpoints = ['users', 'posts', 'comments', 'categories']

# Sequential (slow)
puts "\n  Sequential API calls:"
start_time = Time.now
sequential_results = endpoints.map { |e| fetch_api(e) }
sequential_time = Time.now - start_time
puts "  Results: #{sequential_results.length} responses"
puts "  Time: #{(sequential_time * 1000).round(0)} ms"

# Parallel (fast)
puts "\n  Parallel API calls:"
start_time = Time.now
threads = endpoints.map { |e| Thread.new { fetch_api(e) } }
parallel_results = threads.map(&:value)
parallel_time = Time.now - start_time
puts "  Results: #{parallel_results.length} responses"
puts "  Time: #{(parallel_time * 1000).round(0)} ms"

puts "\n  ⚡ Parallel was #{(sequential_time / parallel_time).round(1)}x faster!"

# ============================================================
# PART 10: Ractors (Ruby 3.0+ True Parallelism)
# ============================================================

puts "\n📌 PART 10: Ractors (Ruby 3.0+ True Parallelism)"
puts "-" * 40

if RUBY_VERSION >= "3.0"
  start_time = Time.now

  # Create Ractors for true parallel execution
  ractors = 4.times.map do |i|
    start_idx = i * chunk_size
    end_idx = (i == 3) ? numbers.length : (i + 1) * chunk_size
    chunk = numbers[start_idx...end_idx]

    Ractor.new(chunk) do |nums|
      nums.sum
    end
  end

  # Collect results
  ractor_sum = ractors.map(&:take).sum

  end_time = Time.now

  puts "  TRUE parallel execution with Ractors"
  puts "  Expected: #{single_thread_sum}"
  puts "  Got:      #{ractor_sum}"
  puts "  Correct?: #{ractor_sum == single_thread_sum ? '✅ Yes' : '❌ No'}"
  puts "  Time: #{((end_time - start_time) * 1000).round(2)} ms"
else
  puts "  Ractors require Ruby 3.0+"
  puts "  Your version: #{RUBY_VERSION}"
end

# ============================================================
# SUMMARY
# ============================================================

puts "\n" + "=" * 60
puts "SUMMARY: Thread Safety Patterns"
puts "=" * 60

puts <<~SUMMARY

  ❌ WRONG: Shared mutable state without protection
     shared_sum += value  # Race condition!

  ✅ CORRECT: Mutex for synchronization
     mutex.synchronize { shared_sum += value }

  ✅ BETTER: Thread-local computation, collect results
     threads.map(&:value).sum

  ✅ BEST: Queue for producer-consumer
     queue << work; results << worker.pop.process

  Key Concepts:
  ┌─────────────────┬──────────────────────────────────────┐
  │ Thread.new      │ Create a new thread                  │
  │ thread.join     │ Wait for thread to complete          │
  │ thread.value    │ Get return value (waits if needed)   │
  │ Mutex           │ Mutual exclusion lock                │
  │ mutex.synchronize│ Execute block with lock held        │
  │ Queue           │ Thread-safe FIFO queue               │
  │ Ractor          │ True parallelism (Ruby 3.0+)         │
  └─────────────────┴──────────────────────────────────────┘

SUMMARY

puts "Run this file again to see race conditions in action!"
puts "=" * 60
