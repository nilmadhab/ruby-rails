# Threading and Concurrency in Ruby

A comprehensive guide to understanding threads, concurrency, and parallelism in Ruby.

---

## Table of Contents

1. [Concurrency vs Parallelism](#1-concurrency-vs-parallelism)
2. [Ruby's GIL (Global Interpreter Lock)](#2-rubys-gil)
3. [Creating Threads](#3-creating-threads)
4. [Race Conditions](#4-race-conditions)
5. [Thread Safety with Mutex](#5-thread-safety-with-mutex)
6. [Thread Communication with Queue](#6-thread-communication-with-queue)
7. [Thread Pools](#7-thread-pools)
8. [Ractors (True Parallelism)](#8-ractors-true-parallelism)
9. [When to Use Threads](#9-when-to-use-threads)
10. [Common Patterns](#10-common-patterns)

---

## 1. Concurrency vs Parallelism

### The Difference

```
CONCURRENCY (One chef, multiple dishes)
┌─────────────────────────────────────────────────────┐
│  Time →                                             │
│  ┌────┐    ┌────┐    ┌────┐    ┌────┐              │
│  │ A  │    │ B  │    │ A  │    │ B  │   One core   │
│  └────┘    └────┘    └────┘    └────┘              │
│  Task A    Task B    Task A    Task B              │
│            (switching between tasks)                │
└─────────────────────────────────────────────────────┘

PARALLELISM (Multiple chefs, multiple dishes)
┌─────────────────────────────────────────────────────┐
│  Time →                                             │
│  ┌──────────────────────────┐                       │
│  │     Task A               │   Core 1             │
│  └──────────────────────────┘                       │
│  ┌──────────────────────────┐                       │
│  │     Task B               │   Core 2             │
│  └──────────────────────────┘                       │
│            (truly simultaneous)                     │
└─────────────────────────────────────────────────────┘
```

| Aspect | Concurrency | Parallelism |
|--------|-------------|-------------|
| Definition | Managing multiple tasks | Executing multiple tasks simultaneously |
| CPU Cores | Works with one core | Requires multiple cores |
| Ruby | Threads (with GIL) | Ractors, Processes |
| Best for | I/O-bound tasks | CPU-bound tasks |

---

## 2. Ruby's GIL

### What is the GIL?

The **Global Interpreter Lock (GIL)**, also called **GVL (Global VM Lock)**, is a mutex that allows only ONE thread to execute Ruby code at a time.

```
┌─────────────────────────────────────────────────────┐
│                    Ruby Process                      │
│  ┌─────────────────────────────────────────────┐    │
│  │              GIL (Lock)                      │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │    │
│  │  │Thread 1 │  │Thread 2 │  │Thread 3 │     │    │
│  │  │ RUNNING │  │ WAITING │  │ WAITING │     │    │
│  │  └─────────┘  └─────────┘  └─────────┘     │    │
│  │       ▲                                     │    │
│  │       └── Only one can run at a time!       │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Why Does Ruby Have a GIL?

1. **Memory Safety** - Prevents data corruption
2. **Simpler Implementation** - Easier to maintain
3. **C Extension Safety** - Many gems assume single-threaded access

### GIL is Released During I/O

```ruby
# Thread 1 makes API call
Thread.new do
  Net::HTTP.get('api.example.com', '/users')  # GIL released while waiting!
end

# Thread 2 can run while Thread 1 waits for network
Thread.new do
  # This runs while Thread 1 is waiting
  process_something
end
```

### Alternatives for True Parallelism

| Option | Description | Use Case |
|--------|-------------|----------|
| **Ractors** | Actor-based parallelism (Ruby 3.0+) | CPU-bound parallel tasks |
| **Process.fork** | Separate processes | Heavy computation |
| **JRuby** | No GIL | Enterprise apps |
| **TruffleRuby** | No GIL, high performance | Performance-critical |

---

## 3. Creating Threads

### Basic Thread Creation

```ruby
# Create and start a thread
thread = Thread.new do
  puts "Hello from thread!"
  sleep(1)
  puts "Thread done!"
end

puts "Main thread continues..."
thread.join  # Wait for thread to finish
puts "All done!"
```

### Thread with Return Value

```ruby
thread = Thread.new do
  # Calculate something
  (1..1000).sum
end

# .value waits for completion and returns the result
result = thread.value
puts "Sum is: #{result}"  # => 500500
```

### Multiple Threads

```ruby
threads = 5.times.map do |i|
  Thread.new(i) do |num|
    sleep(rand)
    puts "Thread #{num} finished"
    num * 10  # Return value
  end
end

# Wait for all and collect results
results = threads.map(&:value)
puts results.inspect  # => [0, 10, 20, 30, 40]
```

### Thread Methods

```ruby
thread = Thread.new { sleep(10) }

thread.alive?    # => true (still running)
thread.status    # => "sleep" or "run" or false/nil
thread.join      # Block until thread completes
thread.join(5)   # Wait max 5 seconds
thread.value     # Get return value (blocks)
thread.kill      # Terminate thread (use with caution!)

Thread.current   # Current thread object
Thread.list      # All threads in process
Thread.main      # Main thread
```

---

## 4. Race Conditions

### What is a Race Condition?

When multiple threads access shared data and the result depends on the timing of execution.

```ruby
# DANGER: Race Condition Example
counter = 0

threads = 10.times.map do
  Thread.new do
    1000.times do
      counter += 1  # NOT atomic!
    end
  end
end

threads.each(&:join)
puts counter  # Expected: 10000, Actual: ??? (unpredictable!)
```

### Why Does This Happen?

```ruby
counter += 1

# Is actually THREE operations:
# 1. Read counter value
# 2. Add 1 to it
# 3. Write back to counter

# Two threads can interleave:
# Thread A: Read counter (0)
# Thread B: Read counter (0)
# Thread A: Add 1 (1)
# Thread B: Add 1 (1)
# Thread A: Write (1)
# Thread B: Write (1)
# Result: 1 instead of 2!
```

### Visual Representation

```
Time →
         Thread A              Thread B
         ────────              ────────
    t1   Read: 0
    t2                         Read: 0
    t3   Compute: 0+1=1
    t4                         Compute: 0+1=1
    t5   Write: 1
    t6                         Write: 1

    Final value: 1 (should be 2!)
```

---

## 5. Thread Safety with Mutex

### What is a Mutex?

**Mutex** (Mutual Exclusion) is a lock that ensures only one thread can execute a critical section at a time.

```ruby
mutex = Mutex.new
counter = 0

threads = 10.times.map do
  Thread.new do
    1000.times do
      mutex.synchronize do
        counter += 1  # Only one thread at a time!
      end
    end
  end
end

threads.each(&:join)
puts counter  # Always 10000!
```

### How Mutex Works

```
Without Mutex:
┌──────────┐  ┌──────────┐
│ Thread A │  │ Thread B │
│  ↓ ↓ ↓   │  │  ↓ ↓ ↓   │   Both access shared data!
└────┬─────┘  └────┬─────┘
     ▼             ▼
  ┌─────────────────┐
  │   Shared Data   │  ← CHAOS!
  └─────────────────┘

With Mutex:
┌──────────┐  ┌──────────┐
│ Thread A │  │ Thread B │
│  ↓ ↓ ↓   │  │  WAITING │
└────┬─────┘  └──────────┘
     ▼
  ┌──────┐
  │ LOCK │ ← Only one can hold the lock
  └──┬───┘
     ▼
  ┌─────────────────┐
  │   Shared Data   │  ← Safe!
  └─────────────────┘
```

### Mutex Best Practices

```ruby
mutex = Mutex.new

# GOOD: Keep critical section small
def increment(mutex, counter)
  # Do computation outside lock
  value_to_add = expensive_calculation

  # Only lock for the shared state update
  mutex.synchronize do
    @counter += value_to_add
  end
end

# BAD: Holding lock too long
def bad_increment(mutex)
  mutex.synchronize do
    expensive_calculation  # Don't do this inside lock!
    @counter += 1
  end
end
```

### Deadlock

```ruby
# DANGER: Deadlock Example
mutex_a = Mutex.new
mutex_b = Mutex.new

thread1 = Thread.new do
  mutex_a.synchronize do
    sleep(0.1)
    mutex_b.synchronize do  # Waiting for mutex_b
      puts "Thread 1"
    end
  end
end

thread2 = Thread.new do
  mutex_b.synchronize do
    sleep(0.1)
    mutex_a.synchronize do  # Waiting for mutex_a
      puts "Thread 2"
    end
  end
end

# Both threads wait forever!
```

**Avoid Deadlock:**
- Always acquire locks in the same order
- Use timeout: `mutex.try_lock`
- Design to minimize shared state

---

## 6. Thread Communication with Queue

### Thread-Safe Queue

Ruby's `Queue` class is thread-safe and perfect for producer-consumer patterns.

```ruby
require 'thread'

queue = Queue.new

# Producer thread
producer = Thread.new do
  5.times do |i|
    queue << "Item #{i}"
    puts "Produced: Item #{i}"
    sleep(0.1)
  end
  queue << :done  # Signal completion
end

# Consumer thread
consumer = Thread.new do
  loop do
    item = queue.pop  # Blocks until item available
    break if item == :done
    puts "Consumed: #{item}"
  end
end

producer.join
consumer.join
```

### Multiple Consumers (Worker Pool)

```ruby
queue = Queue.new
results = Queue.new

# Add work items
10.times { |i| queue << i }

# Create worker threads
workers = 3.times.map do |worker_id|
  Thread.new do
    while !queue.empty?
      begin
        item = queue.pop(true)  # non-blocking
        results << item * 2
        puts "Worker #{worker_id} processed #{item}"
      rescue ThreadError
        break  # Queue empty
      end
    end
  end
end

workers.each(&:join)

# Collect results
output = []
output << results.pop until results.empty?
puts "Results: #{output.sort}"
```

### SizedQueue (Bounded Queue)

```ruby
# Queue with max size - blocks producer when full
queue = SizedQueue.new(5)  # Max 5 items

producer = Thread.new do
  20.times do |i|
    queue << i  # Blocks if queue has 5 items
    puts "Added #{i}, queue size: #{queue.size}"
  end
end

consumer = Thread.new do
  20.times do
    sleep(0.1)  # Slow consumer
    item = queue.pop
    puts "Got #{item}"
  end
end

producer.join
consumer.join
```

---

## 7. Thread Pools

### Why Thread Pools?

- **Reuse threads** - Creating threads is expensive
- **Limit concurrency** - Prevent resource exhaustion
- **Manage work** - Queue tasks for processing

### Simple Thread Pool

```ruby
class ThreadPool
  def initialize(size)
    @size = size
    @jobs = Queue.new
    @workers = []

    @size.times do
      @workers << Thread.new do
        loop do
          job = @jobs.pop
          break if job == :shutdown
          job.call
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
end

# Usage
pool = ThreadPool.new(4)

10.times do |i|
  pool.schedule do
    puts "Processing job #{i} in thread #{Thread.current.object_id}"
    sleep(0.5)
  end
end

sleep(3)  # Wait for jobs
pool.shutdown
```

### Thread Pool with Results

```ruby
class ThreadPoolWithResults
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
          result = job.call
          @results << result
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
    arr = []
    arr << @results.pop until @results.empty?
    arr
  end
end

# Usage: Parallel calculations
pool = ThreadPoolWithResults.new(4)

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
numbers.each do |n|
  pool.schedule { n ** 2 }
end

sleep(1)
pool.shutdown
puts pool.results.inspect  # [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```

---

## 8. Ractors (True Parallelism)

### What are Ractors?

Ractors (Ruby Actors) provide true parallel execution without GIL limitations. Available in Ruby 3.0+.

```ruby
# Create a Ractor
ractor = Ractor.new do
  "Hello from Ractor!"
end

# Get result
puts ractor.take  # => "Hello from Ractor!"
```

### Parallel Computation with Ractors

```ruby
# Sum numbers in parallel using 4 Ractors
numbers = (1..1_000_000).to_a
chunk_size = numbers.length / 4

ractors = 4.times.map do |i|
  start_idx = i * chunk_size
  end_idx = (i == 3) ? numbers.length : (i + 1) * chunk_size
  chunk = numbers[start_idx...end_idx]

  Ractor.new(chunk) do |nums|
    nums.sum
  end
end

total = ractors.map(&:take).sum
puts "Sum: #{total}"  # => 500000500000
```

### Ractor Communication

```ruby
# Send messages between Ractors
worker = Ractor.new do
  loop do
    msg = Ractor.receive  # Wait for message
    break if msg == :quit
    Ractor.yield(msg.upcase)  # Send result back
  end
end

# Send work
worker.send("hello")
puts worker.take  # => "HELLO"

worker.send("world")
puts worker.take  # => "WORLD"

worker.send(:quit)
```

### Ractor Limitations

```ruby
# Ractors cannot share mutable objects
shared_array = [1, 2, 3]

# This will ERROR:
Ractor.new(shared_array) do |arr|
  arr << 4  # Can't modify shared object!
end

# Must pass copies or immutable data:
Ractor.new(shared_array.dup) do |arr|
  arr << 4  # OK - working with copy
end
```

---

## 9. When to Use Threads

### Good Use Cases (I/O Bound)

```ruby
# ✅ Multiple API calls
urls = ['api1.com', 'api2.com', 'api3.com']
threads = urls.map do |url|
  Thread.new { fetch_data(url) }
end
results = threads.map(&:value)

# ✅ Multiple database queries
threads = [
  Thread.new { User.count },
  Thread.new { Post.count },
  Thread.new { Comment.count }
]
counts = threads.map(&:value)

# ✅ Reading multiple files
files = Dir['*.txt']
threads = files.map do |file|
  Thread.new { File.read(file) }
end
contents = threads.map(&:value)

# ✅ Web server handling requests (Puma)
# Each request in a thread, waiting for DB/APIs
```

### Bad Use Cases (CPU Bound)

```ruby
# ❌ Heavy computation (GIL prevents parallelism)
# Use Ractors or Process.fork instead

# ❌ Number crunching
threads = data_chunks.map do |chunk|
  Thread.new { heavy_math(chunk) }  # Won't be faster!
end

# ✅ Use Ractors instead
ractors = data_chunks.map do |chunk|
  Ractor.new(chunk) { |c| heavy_math(c) }
end
```

### Decision Tree

```
Is your task I/O bound?
(waiting for network, disk, database)
         │
    ┌────┴────┐
    │         │
   YES        NO (CPU bound)
    │         │
 Use Threads  Use Ractors/Processes
```

---

## 10. Common Patterns

### Pattern 1: Parallel Map

```ruby
def parallel_map(array, thread_count: 4, &block)
  results = Array.new(array.length)
  mutex = Mutex.new
  index = -1

  threads = thread_count.times.map do
    Thread.new do
      loop do
        i = mutex.synchronize { index += 1 }
        break if i >= array.length
        results[i] = block.call(array[i])
      end
    end
  end

  threads.each(&:join)
  results
end

# Usage
squares = parallel_map([1, 2, 3, 4, 5]) { |n| n ** 2 }
puts squares.inspect  # => [1, 4, 9, 16, 25]
```

### Pattern 2: Future/Promise

```ruby
class Future
  def initialize(&block)
    @thread = Thread.new(&block)
  end

  def value
    @thread.value
  end

  def ready?
    !@thread.alive?
  end
end

# Usage
future1 = Future.new { expensive_api_call }
future2 = Future.new { another_api_call }

# Do other work...
puts "Doing other things..."

# Get results when needed
result1 = future1.value
result2 = future2.value
```

### Pattern 3: Timeout

```ruby
def with_timeout(seconds)
  thread = Thread.new { yield }

  if thread.join(seconds)
    thread.value
  else
    thread.kill
    raise Timeout::Error, "Operation timed out"
  end
end

# Usage
begin
  result = with_timeout(5) do
    slow_operation
  end
rescue Timeout::Error
  puts "Operation took too long!"
end
```

### Pattern 4: Read-Write Lock

```ruby
class ReadWriteLock
  def initialize
    @mutex = Mutex.new
    @readers = 0
    @writer = false
  end

  def read
    @mutex.synchronize do
      sleep(0.01) while @writer
      @readers += 1
    end

    yield
  ensure
    @mutex.synchronize { @readers -= 1 }
  end

  def write
    @mutex.synchronize do
      sleep(0.01) while @writer || @readers > 0
      @writer = true
    end

    yield
  ensure
    @mutex.synchronize { @writer = false }
  end
end

# Usage
lock = ReadWriteLock.new
data = []

# Multiple readers OK
threads = 5.times.map do
  Thread.new do
    lock.read { puts data.inspect }
  end
end

# Writer has exclusive access
Thread.new do
  lock.write { data << "new item" }
end
```

---

## Quick Reference

| Concept | Description | Example |
|---------|-------------|---------|
| `Thread.new` | Create thread | `Thread.new { work }` |
| `thread.join` | Wait for completion | `thread.join` |
| `thread.value` | Get return value | `result = thread.value` |
| `Mutex` | Lock for safety | `mutex.synchronize { }` |
| `Queue` | Thread-safe queue | `queue << item; queue.pop` |
| `Ractor` | True parallelism | `Ractor.new { work }` |
| `SizedQueue` | Bounded queue | `SizedQueue.new(10)` |

## Resources

- [Ruby Thread Documentation](https://ruby-doc.org/core/Thread.html)
- [Ruby Ractor Documentation](https://ruby-doc.org/core/Ractor.html)
- [Concurrent Ruby Gem](https://github.com/ruby-concurrency/concurrent-ruby)

---

Run the demo: `ruby threading_demo.rb`
