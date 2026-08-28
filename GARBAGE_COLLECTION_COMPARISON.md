# Garbage Collection: Go vs Ruby vs Java

A comprehensive comparison of garbage collection mechanisms across three popular languages.

---

## Quick Comparison

| Aspect | Go | Ruby | Java |
|--------|-----|------|------|
| GC Type | Concurrent, Tri-color Mark & Sweep | Generational Mark & Sweep | Generational (Multiple collectors) |
| Pause Time | < 1ms (typical) | 10-100ms+ | Varies (1ms to seconds) |
| Tuning Options | Minimal (GOGC) | Limited | Extensive |
| Memory Overhead | Low | High | Medium-High |
| Predictability | High | Low | Medium |
| Best For | Low latency services | Developer productivity | Enterprise applications |

---

## 1. Go Garbage Collection

### Algorithm: Concurrent Tri-color Mark & Sweep

Go uses a **non-generational**, **concurrent**, **tri-color mark and sweep** collector.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    Tri-Color Marking                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   WHITE (Garbage)    GRAY (Processing)    BLACK (Alive) │
│   ┌───┐              ┌───┐                ┌───┐         │
│   │   │ ──────────►  │   │ ──────────►    │   │         │
│   └───┘              └───┘                └───┘         │
│   Not visited        In progress          Visited       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Phases:**
1. **Mark Setup** (STW) - Very brief stop-the-world
2. **Marking** (Concurrent) - Marks live objects while program runs
3. **Mark Termination** (STW) - Brief pause to finish marking
4. **Sweeping** (Concurrent) - Reclaims white objects

### Key Features

```go
// Tuning with GOGC environment variable
// GOGC=100 (default) - GC runs when heap doubles
// GOGC=200 - GC runs when heap triples
// GOGC=off - Disable GC

// Force GC
runtime.GC()

// Get GC stats
var stats runtime.MemStats
runtime.ReadMemStats(&stats)
fmt.Printf("Heap: %d MB\n", stats.HeapAlloc/1024/1024)
fmt.Printf("GC Cycles: %d\n", stats.NumGC)
```

### Pros
- **Ultra-low pause times** (< 1ms typically)
- **Predictable latency**
- **Simple tuning** (just GOGC)
- **No generational overhead**

### Cons
- **Higher CPU usage** during GC
- **No generational optimization** (scans all objects)
- **Less throughput** compared to generational collectors

### When GC Triggers
- Heap grows to 2x (default GOGC=100)
- Explicit `runtime.GC()`
- Every 2 minutes if idle

---

## 2. Ruby Garbage Collection

### Algorithm: Generational Mark & Sweep (since Ruby 2.1)

Ruby uses a **generational**, **incremental**, **mark and sweep** collector.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  Ruby Generations                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   Young Generation          Old Generation               │
│   ┌─────────────────┐      ┌─────────────────┐          │
│   │ New objects     │ ──►  │ Survived 3+ GCs │          │
│   │ (Minor GC)      │      │ (Major GC)      │          │
│   └─────────────────┘      └─────────────────┘          │
│   Collected frequently     Collected rarely              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**GC Types:**
1. **Minor GC** - Only scans young generation (fast)
2. **Major GC** - Scans all objects (slow, stop-the-world)

### Key Features

```ruby
# Force GC
GC.start

# Disable/Enable GC
GC.disable
GC.enable

# GC Statistics
puts GC.stat
# {
#   count: 15,           # Total GC runs
#   minor_gc_count: 12,  # Minor GC runs
#   major_gc_count: 3,   # Major GC runs
#   heap_live_slots: 25000,
#   heap_free_slots: 5000,
#   ...
# }

# Tune GC with environment variables
# RUBY_GC_HEAP_INIT_SLOTS=600000
# RUBY_GC_HEAP_FREE_SLOTS=200000
# RUBY_GC_HEAP_GROWTH_FACTOR=1.25
# RUBY_GC_MALLOC_LIMIT=16000000
```

### Memory Layout

```
┌─────────────────────────────────────────┐
│              Ruby Heap                   │
├─────────────────────────────────────────┤
│  Page 1    │  Page 2    │  Page 3  ...  │
│  ┌──┬──┐   │  ┌──┬──┐   │               │
│  │Ob│Ob│   │  │Ob│  │   │               │
│  └──┴──┘   │  └──┴──┘   │               │
│  Slots     │  Slots     │               │
└─────────────────────────────────────────┘
Each slot = 40 bytes (RVALUE)
```

### Pros
- **Generational** reduces GC frequency
- **Incremental marking** (Ruby 2.2+)
- **Simple for developers** (automatic)
- **Compaction** available (Ruby 2.7+)

### Cons
- **Stop-the-world pauses** (major GC)
- **Global Interpreter Lock (GIL)** limits concurrency
- **High memory overhead**
- **Unpredictable pause times**

### Ruby 3.x Improvements
- Better compaction (`GC.compact`)
- Variable Width Allocation (Ruby 3.2)
- Reduced memory fragmentation

---

## 3. Java Garbage Collection

### Multiple Collectors Available

Java offers several GC implementations:

| Collector | Best For | Pause Time | Throughput |
|-----------|----------|------------|------------|
| Serial GC | Single-threaded apps | High | Low |
| Parallel GC | Batch processing | Medium | High |
| G1 GC (default) | Balanced workloads | Low-Medium | Medium |
| ZGC | Low latency (< 1ms) | Ultra-low | Medium |
| Shenandoah | Low latency | Ultra-low | Medium |

### Generational Heap Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        Java Heap                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Young Generation                    Old Generation         │
│   ┌─────────┬─────────┬─────────┐    ┌─────────────────┐    │
│   │  Eden   │Survivor │Survivor │    │                 │    │
│   │         │   S0    │   S1    │───►│   Tenured       │    │
│   └─────────┴─────────┴─────────┘    │                 │    │
│   New objects created here           └─────────────────┘    │
│                                       Long-lived objects     │
│                                                              │
│   ┌─────────────────┐                                        │
│   │   Metaspace     │  (Class metadata, method info)        │
│   └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

### G1 GC (Garbage First) - Default since Java 9

```
┌─────────────────────────────────────────────────────────────┐
│                    G1 Heap Regions                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐                │
│   │ E │ E │ S │ O │ O │ E │ H │ O │ E │ S │                │
│   └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘                │
│                                                              │
│   E = Eden    S = Survivor    O = Old    H = Humongous      │
│                                                              │
│   - Heap divided into equal-sized regions                    │
│   - Collects regions with most garbage first                │
│   - Predictable pause times                                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

```java
// JVM GC Options
// -XX:+UseG1GC              (G1 - default)
// -XX:+UseZGC               (ZGC - ultra-low latency)
// -XX:+UseShenandoahGC      (Shenandoah)
// -XX:+UseParallelGC        (Parallel - throughput)

// Heap sizing
// -Xms512m                  (Initial heap)
// -Xmx4g                    (Max heap)
// -XX:MaxGCPauseMillis=200  (Target pause time)

// Force GC (not recommended in production)
System.gc();

// GC Logging
// -Xlog:gc*:file=gc.log
```

### ZGC (Ultra-Low Latency)

```
┌─────────────────────────────────────────────────────────────┐
│                         ZGC                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Features:                                                  │
│   - Pause times < 1ms (regardless of heap size)             │
│   - Supports multi-terabyte heaps                           │
│   - Concurrent compaction                                    │
│   - Uses colored pointers                                    │
│                                                              │
│   Best for:                                                  │
│   - Large heaps (8GB+)                                       │
│   - Latency-sensitive applications                          │
│   - Real-time systems                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Pros
- **Multiple GC options** for different needs
- **Highly tunable**
- **ZGC/Shenandoah** for ultra-low latency
- **Excellent tooling** (VisualVM, JFR, etc.)
- **Mature and battle-tested**

### Cons
- **Complex tuning** (many options)
- **Warmup time** for JIT + GC
- **Memory overhead** (especially G1)
- **Requires expertise** to optimize

---

## 4. Detailed Comparison

### Pause Times

```
┌─────────────────────────────────────────────────────────────┐
│                   Typical Pause Times                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Go          │████                          │ < 1ms        │
│   Java (ZGC)  │████                          │ < 1ms        │
│   Java (G1)   │████████████                  │ 10-200ms     │
│   Ruby        │████████████████████████████  │ 50-500ms+    │
│                                                              │
│               0ms        100ms       200ms        500ms      │
└─────────────────────────────────────────────────────────────┘
```

### Memory Efficiency

```
┌─────────────────────────────────────────────────────────────┐
│          Memory Overhead (for same workload)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Go          │████████████                  │ ~1.5x        │
│   Java        │████████████████████          │ ~2-3x        │
│   Ruby        │████████████████████████████  │ ~3-5x        │
│                                                              │
│               1x          2x          3x          5x         │
│               (baseline)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Throughput vs Latency

```
                    High Throughput
                          ▲
                          │
            Java          │
           (Parallel)     │
                          │
                    Java  │
                    (G1)  │
                          │
        Ruby              │        Go
                          │     Java (ZGC)
                          │
     ─────────────────────┼─────────────────────►
     High Latency         │              Low Latency
                          │
```

---

## 5. GC Algorithms Summary

### Mark and Sweep
```
Phase 1: Mark          Phase 2: Sweep
┌───┬───┬───┬───┐     ┌───┬───┬───┬───┐
│ ✓ │   │ ✓ │   │ ──► │ A │   │ B │   │
└───┴───┴───┴───┘     └───┴───┴───┴───┘
Mark reachable         Free unmarked
```
**Used by:** Go, Ruby (basic)

### Generational
```
Young Gen (frequent GC)     Old Gen (rare GC)
┌─────────────────────┐    ┌─────────────────┐
│ New objects         │───►│ Survived objects│
│ Most die young      │    │ Long-lived      │
└─────────────────────┘    └─────────────────┘
```
**Used by:** Ruby, Java

### Copying
```
From Space             To Space
┌───┬───┬───┬───┐     ┌───┬───┬───┬───┐
│ A │ x │ B │ x │ ──► │ A │ B │   │   │
└───┴───┴───┴───┘     └───┴───┴───┴───┘
                       Compacted!
```
**Used by:** Java (Young Gen)

### Concurrent
```
Application    ████████████████████████████████
GC Thread      ░░░░████████░░░░░░░░████░░░░░░░░
                   Marking         Sweeping
               ▲                   ▲
               │                   │
            Brief STW          Brief STW
```
**Used by:** Go, Java (G1, ZGC)

---

## 6. When to Use Which Language

### Choose Go When:
- Building microservices
- Low latency is critical (< 10ms p99)
- Predictable performance needed
- DevOps/infrastructure tools
- You want simple deployment (single binary)

### Choose Ruby When:
- Rapid prototyping
- Developer productivity > performance
- Web applications (Rails)
- Startup MVPs
- GC latency is acceptable

### Choose Java When:
- Enterprise applications
- Need fine-grained GC control
- Large heap sizes (100GB+)
- Long-running server applications
- Existing Java ecosystem

---

## 7. Tuning Cheat Sheet

### Go
```bash
# Basic tuning
GOGC=100          # Default, GC at 2x heap
GOGC=200          # Less frequent GC
GOMEMLIMIT=4GiB   # Hard memory limit (Go 1.19+)
```

### Ruby
```bash
# Environment variables
RUBY_GC_HEAP_INIT_SLOTS=600000
RUBY_GC_HEAP_FREE_SLOTS=200000
RUBY_GC_HEAP_GROWTH_FACTOR=1.25
RUBY_GC_MALLOC_LIMIT=16000000
RUBY_GC_OLDMALLOC_LIMIT=16000000
```

### Java
```bash
# G1 (balanced)
-XX:+UseG1GC -Xms4g -Xmx4g -XX:MaxGCPauseMillis=200

# ZGC (low latency)
-XX:+UseZGC -Xms8g -Xmx8g

# Parallel (throughput)
-XX:+UseParallelGC -Xms4g -Xmx4g
```

---

## 8. Interview Tips

**Common Questions:**

1. **What is Stop-The-World (STW)?**
   - When GC pauses all application threads
   - Go minimizes this, Ruby has significant STW

2. **Why generational GC?**
   - "Weak generational hypothesis": most objects die young
   - Optimize by collecting young objects frequently

3. **How does Go achieve low latency?**
   - Concurrent marking
   - Tri-color invariant
   - Write barriers
   - No generational overhead

4. **When would you choose Java's ZGC over Go?**
   - Need very large heaps (terabytes)
   - Already in Java ecosystem
   - Need sub-millisecond pauses with huge heap

---

## Resources

- [Go GC Guide](https://tip.golang.org/doc/gc-guide)
- [Ruby GC Tuning](https://www.speedshop.co/2017/03/09/a-guide-to-gc-stat.html)
- [Java GC Tuning](https://docs.oracle.com/en/java/javase/17/gctuning/)
- [ZGC Deep Dive](https://malloc.se/blog/zgc-jdk16)
