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
#include <chrono>
#include <vector>
#include <string>

// POSIX headers that work on both QNX and Linux
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/utsname.h>
#include <pthread.h>
#include <semaphore.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <time.h>

// Shared data structure for thread communication
struct ThreadData {
    int thread_id;
    sem_t* semaphore;
    volatile bool* should_exit;
};

void print_system_info() {
    std::cout << "\n=== System Information ===" << std::endl;
    
    // Get system name info using POSIX uname
    struct utsname sys_info;
    if (uname(&sys_info) == 0) {
        std::cout << "System: " << sys_info.sysname << std::endl;
        std::cout << "Node: " << sys_info.nodename << std::endl;
        std::cout << "Release: " << sys_info.release << std::endl;
        std::cout << "Version: " << sys_info.version << std::endl;
        std::cout << "Machine: " << sys_info.machine << std::endl;
    }
    
    // Process information
    std::cout << "Process ID: " << getpid() << std::endl;
    std::cout << "Parent PID: " << getppid() << std::endl;
    std::cout << "User ID: " << getuid() << std::endl;
    std::cout << "Group ID: " << getgid() << std::endl;
    
    // Current working directory
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) != nullptr) {
        std::cout << "Working Directory: " << cwd << std::endl;
    }
}

void test_posix_time() {
    std::cout << "\n=== POSIX Time Functions ===" << std::endl;
    
    // Get current time using POSIX functions
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) == 0) {
        std::cout << "CLOCK_REALTIME: " << ts.tv_sec << "." << ts.tv_nsec << std::endl;
    }
    
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0) {
        std::cout << "CLOCK_MONOTONIC: " << ts.tv_sec << "." << ts.tv_nsec << std::endl;
    }
    
    // Get time using gettimeofday
    struct timeval tv;
    if (gettimeofday(&tv, nullptr) == 0) {
        std::cout << "gettimeofday: " << tv.tv_sec << "." << tv.tv_usec << std::endl;
    }
}

void* worker_thread(void* arg) {
    ThreadData* data = static_cast<ThreadData*>(arg);
    
    std::cout << "Thread " << data->thread_id << " started (pthread_self: " 
              << pthread_self() << ")" << std::endl;
    
    // Wait for semaphore signal
    if (sem_wait(data->semaphore) == 0) {
        std::cout << "Thread " << data->thread_id << " acquired semaphore" << std::endl;
        
        // Do some work
        usleep(100000); // 100ms using POSIX usleep
        
        std::cout << "Thread " << data->thread_id << " releasing semaphore" << std::endl;
        sem_post(data->semaphore);
    }
    
    return nullptr;
}

void test_posix_threads_and_semaphores() {
    std::cout << "\n=== POSIX Threads and Semaphores Test ===" << std::endl;
    
    const int num_threads = 3;
    pthread_t threads[num_threads];
    ThreadData thread_data[num_threads];
    volatile bool should_exit = false;
    
    // Create a named semaphore (works on both QNX and Linux)
    sem_t* semaphore = sem_open("/test_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (semaphore == SEM_FAILED) {
        // Semaphore might already exist, try to open it
        semaphore = sem_open("/test_semaphore", O_RDWR);
        if (semaphore == SEM_FAILED) {
            std::cerr << "Failed to create/open semaphore: " << strerror(errno) << std::endl;
            return;
        }
    }
    
    // Create threads
    for (int i = 0; i < num_threads; ++i) {
        thread_data[i].thread_id = i;
        thread_data[i].semaphore = semaphore;
        thread_data[i].should_exit = &should_exit;
        
        if (pthread_create(&threads[i], nullptr, worker_thread, &thread_data[i]) != 0) {
            std::cerr << "Failed to create thread " << i << std::endl;
            continue;
        }
    }
    
    // Give threads time to start
    usleep(50000); // 50ms
    
    // Signal semaphore multiple times to let threads proceed
    std::cout << "Signaling semaphore for threads..." << std::endl;
    for (int i = 0; i < num_threads; ++i) {
        sem_post(semaphore);
        usleep(200000); // 200ms between signals
    }
    
    // Wait for all threads to complete
    for (int i = 0; i < num_threads; ++i) {
        pthread_join(threads[i], nullptr);
        std::cout << "Thread " << i << " joined" << std::endl;
    }
    
    // Clean up semaphore
    sem_close(semaphore);
    sem_unlink("/test_semaphore");
    
    std::cout << "POSIX threads test completed!" << std::endl;
}

void test_file_operations() {
    std::cout << "\n=== POSIX File Operations ===" << std::endl;
    
    const char* test_file = "/tmp/posix_test_file.txt";
    
    // Create and write to file using POSIX functions
    int fd = open(test_file, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd != -1) {
        const char* message = "Hello from POSIX file operations!\n";
        ssize_t bytes_written = write(fd, message, strlen(message));
        std::cout << "Wrote " << bytes_written << " bytes to " << test_file << std::endl;
        close(fd);
        
        // Get file stats
        struct stat file_stat;
        if (stat(test_file, &file_stat) == 0) {
            std::cout << "File size: " << file_stat.st_size << " bytes" << std::endl;
            std::cout << "File mode: " << std::oct << file_stat.st_mode << std::dec << std::endl;
            std::cout << "Last modified: " << file_stat.st_mtime << std::endl;
        }
        
        // Read file back
        fd = open(test_file, O_RDONLY);
        if (fd != -1) {
            char buffer[256];
            ssize_t bytes_read = read(fd, buffer, sizeof(buffer) - 1);
            if (bytes_read > 0) {
                buffer[bytes_read] = '\0';
                std::cout << "Read back: " << buffer;
            }
            close(fd);
        }
        
        // Clean up
        unlink(test_file);
        std::cout << "Test file cleaned up" << std::endl;
    } else {
        std::cerr << "Failed to create test file: " << strerror(errno) << std::endl;
    }
}

int main(int argc, char* argv[]) {
    std::cout << "=== POSIX Cross-Platform Test (QNX & Linux) ===" << std::endl;
    std::cout << "Arguments: ";
    for (int i = 0; i < argc; ++i) {
        std::cout << argv[i] << " ";
    }
    std::cout << std::endl;
    
    try {
        print_system_info();
        test_posix_time();
        test_file_operations();
        test_posix_threads_and_semaphores();
        
        std::cout << "\n🎉 All POSIX tests completed successfully!" << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "❌ Exception: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
