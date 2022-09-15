#include "io/print.h"

#include <gtest/gtest.h>

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#include <stdexcept>
#include <string>

namespace {

class captureStdout {
public:
    explicit captureStdout(int fd) : replacedFd_(fd) {
        content_.clear();
        if (pipe2(pipe_, O_NONBLOCK) != 0) {
            throw std::runtime_error("Could not create pipe");
        }

        originalFd_ = dup(replacedFd_);
        if (originalFd_ == -1) {
            throw std::runtime_error("Could not duplicate stdout");
        }
        fflush(stdout);
        if (dup2(pipe_[1], replacedFd_) == -1) {
            throw std::runtime_error("Could not redirect stdout to pipe");
        }
    }

    ~captureStdout() {
        close(pipe_[1]);
        dup2(originalFd_, replacedFd_);
        close(originalFd_);

        content_ += readInput();
        close(pipe_[0]);
    }

    static const std::string& content() { return content_; }

private:
    int replacedFd_ = -1;
    int originalFd_ = -1;
    int pipe_[2] = { 0, 0 };
    static std::string content_;

    std::string readInput() {
        std::string out;
        char buffer[256];
        while (true) {
            errno = 0;
            const ssize_t bytes = read(pipe_[0], buffer, sizeof(buffer));
            if (bytes == 0 || bytes == -1) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    usleep(500);
                    continue;
                } else {
                    break;
                }
            }
            out.append(buffer, bytes);
        }
        return out;
    }
};

std::string captureStdout::content_;

TEST(printTest, print_out_n) {
    const char text[] = "123456789";
    {
        captureStdout capture(fileno(stdout));
        EXPECT_EQ(_print_out_n(text, 5), 5);
    }
    EXPECT_EQ(captureStdout::content(), "12345");
    {
        captureStdout capture(fileno(stdout));
        EXPECT_EQ(_print_out_n(text, 6), 6);
    }
    EXPECT_EQ(captureStdout::content(), "123456");
}

TEST(printTest, print_out_z) {
    {
        captureStdout capture(fileno(stdout));
        EXPECT_EQ(_print_out_z("123456789"), 9);
    }
    EXPECT_EQ(captureStdout::content(), "123456789");
    {
        captureStdout capture(fileno(stdout));
        EXPECT_EQ(_print_out_z("some text!"), 10);
    }
    EXPECT_EQ(captureStdout::content(), "some text!");
}

TEST(printTest, print_err_n) {
    const char text[] = "123456789";
    {
        captureStdout capture(fileno(stderr));
        EXPECT_EQ(_print_err_n(text, 5), 5);
    }
    EXPECT_EQ(captureStdout::content(), "12345");
    {
        captureStdout capture(fileno(stderr));
        EXPECT_EQ(_print_err_n(text, 6), 6);
    }
    EXPECT_EQ(captureStdout::content(), "123456");
}

TEST(printTest, print_err_z) {
    {
        captureStdout capture(fileno(stderr));
        EXPECT_EQ(_print_err_z("123456789"), 9);
    }
    EXPECT_EQ(captureStdout::content(), "123456789");
    {
        captureStdout capture(fileno(stderr));
        EXPECT_EQ(_print_err_z("some text!"), 10);
    }
    EXPECT_EQ(captureStdout::content(), "some text!");
}

TEST(printTest, brk_ln_out) {
    {
        captureStdout capture(fileno(stdout));
        EXPECT_EQ(_brk_ln_out(), 1);
    }
    EXPECT_EQ(captureStdout::content(), "\n");
}

TEST(printTest, brk_ln_err) {
    {
        captureStdout capture(fileno(stderr));
        EXPECT_EQ(_brk_ln_err(), 1);
    }
    EXPECT_EQ(captureStdout::content(), "\n");
}

} // namespace
