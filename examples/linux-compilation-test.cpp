// Copyright (c) Sid Menon 2026
// Modifications by : Sid Menon (sidgmenon@gmail.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <iostream>
#include <thread>
#include <mutex>
#include <vector>
#include <chrono>
#include <atomic>
#include <condition_variable>
#include <unistd.h>
#include <sys/types.h>
#include <sys/syscall.h>
#include <linux/limits.h>
#include <pthread.h>
#include <sched.h>

class ThreadSafeCounter {
private:
    mutable std::mutex mtx_;
    std::condition_variable cv_;
    int counter_;
    std::atomic<bool> ready_{false};

public:
    ThreadSafeCounter() : counter_(0) {}

    void increment() {
        std::lock_guard<std::mutex> lock(mtx_);
        ++counter_;
        cv_.notify_one();
    }

    void decrement() {
        std::lock_guard<std::mutex> lock(mtx_);
        --counter_;
        cv_.notify_one();
    }

    int get() const {
        std::lock_guard<std::mutex> lock(mtx_);
        return counter_;
    }

    void wait_for_value(int target) {
        std::unique_lock<std::mutex> lock(mtx_);
        cv_.wait(lock, [this, target] { return counter_ >= target; });
    }

    void set_ready() {
        ready_.store(true);
        cv_.notify_all();
    }

    void wait_until_ready() {
        std::unique_lock<std::mutex> lock(mtx_);
        cv_.wait(lock, [this] { return ready_.load(); });
    }
};

void worker_thread(ThreadSafeCounter& counter, int thread_id, int iterations) {
    // Get thread info using Linux-specific headers
    pid_t tid = syscall(SYS_gettid);
    int cpu = sched_getcpu();
    
    std::cout << "Thread " << thread_id << " starting (TID: " << tid 
              << ", CPU: " << cpu << ")" << std::endl;

    // Wait for all threads to be ready
    counter.wait_until_ready();

    for (int i = 0; i < iterations; ++i) {
        counter.increment();
        
        // Small delay to make concurrency more interesting
        std::this_thread::sleep_for(std::chrono::microseconds(100));
        
        if (i % 10 == 0) {
            std::cout << "Thread " << thread_id << " completed " << i 
                      << " iterations, counter: " << counter.get() << std::endl;
        }
    }
    
    std::cout << "Thread " << thread_id << " finished" << std::endl;
}

void system_info_test() {
    std::cout << "\n=== System Information Test ===" << std::endl;
    
    // Test Linux-specific headers and system calls
    std::cout << "Process ID: " << getpid() << std::endl;
    std::cout << "Thread ID: " << syscall(SYS_gettid) << std::endl;
    std::cout << "Current CPU: " << sched_getcpu() << std::endl;
    std::cout << "Number of processors: " << sysconf(_SC_NPROCESSORS_ONLN) << std::endl;
    std::cout << "Page size: " << sysconf(_SC_PAGESIZE) << " bytes" << std::endl;
    std::cout << "PATH_MAX: " << PATH_MAX << std::endl;
    std::cout << "NAME_MAX: " << NAME_MAX << std::endl;
    
    // Test pthread attributes
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    
    size_t stack_size;
    if (pthread_attr_getstacksize(&attr, &stack_size) == 0) {
        std::cout << "Default thread stack size: " << stack_size << " bytes" << std::endl;
    }
    
    pthread_attr_destroy(&attr);
}

void mutex_stress_test() {
    std::cout << "\n=== Mutex Stress Test ===" << std::endl;
    
    const int num_threads = 4;
    const int iterations_per_thread = 50;
    
    ThreadSafeCounter counter;
    std::vector<std::thread> threads;
    
    // Create threads
    for (int i = 0; i < num_threads; ++i) {
        threads.emplace_back(worker_thread, std::ref(counter), i, iterations_per_thread);
    }
    
    // Let threads initialize
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    std::cout << "Starting all threads..." << std::endl;
    counter.set_ready();
    
    // Wait for a specific value
    std::thread waiter([&counter, num_threads, iterations_per_thread] {
        int target = (num_threads * iterations_per_thread) / 2;
        std::cout << "Waiting for counter to reach " << target << "..." << std::endl;
        counter.wait_for_value(target);
        std::cout << "Counter reached " << target << "!" << std::endl;
    });
    
    // Join all worker threads
    for (auto& thread : threads) {
        thread.join();
    }
    
    waiter.join();
    
    std::cout << "Final counter value: " << counter.get() << std::endl;
    std::cout << "Expected value: " << num_threads * iterations_per_thread << std::endl;
    
    if (counter.get() == num_threads * iterations_per_thread) {
        std::cout << "✅ Mutex test PASSED!" << std::endl;
    } else {
        std::cout << "❌ Mutex test FAILED!" << std::endl;
    }
}

int main() {
    std::cout << "=== Linux Headers and Mutex Test Program ===" << std::endl;
    
    try {
        system_info_test();
        mutex_stress_test();
        
        std::cout << "\n=== Test completed successfully! ===" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}