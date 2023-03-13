#include "memory_test_utils.h"

#include "memory/linear.h"
#include "memory/utils.h"

#include <errno.h>
#include <gtest/gtest.h>

#include <cctype>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <limits>
#include <ostream>
#include <random>
#include <sstream>

namespace memory {
namespace {

struct MavhT {
    constexpr explicit MavhT(uint64_t mavh)
          : x_(mavh >> 58),
            y_((mavh >> 52) & 0x3f),
            num_free_((mavh >> 26) & 0x3ff'ffff),
            num_used_(mavh & 0x3ff'ffff) {}
    explicit MavhT(uint64_t mem_size, uint64_t mav_size, uint64_t n_free, uint64_t n_used)
          : x_(mem_size_index(mem_size)),
            y_(mem_size_index(mav_size)),
            num_free_(n_free),
            num_used_(n_used) {}
    friend std::ostream& operator<<(std::ostream& out, const MavhT& mavh) {
        constexpr uint64_t one = 1;
        out << "MAVH - "
            << "mem size = " << mavh.x_ << " ==> " << (one << mavh.x_) << " / "
            << "mav size = " << mavh.y_ << " ==> " << (one << mavh.y_) << " / "
            << "segs free = " << mavh.num_free_ << " / "
            << "segs_used = " << mavh.num_used_;
        return out;
    }
    friend constexpr bool operator==(const MavhT& x, const MavhT& y) {
        return x.x_ == y.x_ && x.y_ == y.y_ && x.num_free_ == y.num_free_
               && x.num_used_ == y.num_used_;
    }
    friend constexpr bool operator!=(const MavhT& x, const MavhT& y) { return not(x == y); }
    constexpr uint64_t ToMavh() const {
        return (x_ << 58) + (y_ << 52) + (num_free_ << 26) + num_used_;
    }
    std::string ToString() const {
        std::stringstream out;
        out << *this;
        return out.str();
    }
    constexpr uint64_t X() const { return x_; }
    constexpr uint64_t Y() const { return y_; }
    constexpr uint64_t MemSz() const {
        constexpr uint64_t one = 1;
        return one << x_;
    }
    constexpr uint64_t MavSz() const {
        constexpr uint64_t one = 1;
        return one << y_;
    }
    constexpr uint64_t FullSz() const { return MemSz() + MavSz(); }
    constexpr uint64_t NumFree() const { return num_free_; }
    constexpr uint64_t NumUsed() const { return num_used_; }

private:
    uint64_t x_;
    uint64_t y_;
    uint64_t num_free_;
    uint64_t num_used_;
};

struct MshT {
    constexpr explicit MshT(uint64_t msh) : o_(msh >> 32), s_(msh & 0xffff'ffff) {}
    constexpr explicit MshT(uint64_t offset, uint64_t size) : o_(offset / 8), s_(size / 8) {}
    friend std::ostream& operator<<(std::ostream& out, const MshT& msh) {
        out << "MSH - "
            << "o/s = " << msh.o_ << " / " << msh.s_ << " | "
            << "offset/size = " << msh.o_ * 8 << " / " << msh.s_ * 8;
        return out;
    }
    friend constexpr bool operator==(const MshT& x, const MshT& y) {
        return x.s_ == y.s_ && x.o_ == y.o_;
    }
    friend constexpr bool operator!=(const MshT& x, const MshT& y) { return not(x == y); }
    constexpr uint64_t ToMsh() const { return (o_ << 32) + s_; }
    std::string ToString() const {
        std::stringstream out;
        out << *this;
        return out.str();
    }
    constexpr uint64_t O() const { return o_; }
    constexpr uint64_t S() const { return s_; }
    constexpr uint64_t Offset() const { return o_ * 8; }
    constexpr uint64_t Size() const { return s_ * 8; }
    void ReduceSize(const MshT& y) { s_ -= y.s_; }
    void IncreaseSize(const MshT& y) { s_ += y.s_; }
    constexpr bool FollowedBy(const MshT& x) const { return Offset() + Size() == x.Offset(); }

    static MshT GetAt(const uint8_t* buffer, size_t offset) {
        uint64_t val;
        std::memcpy(&val, buffer + offset, sizeof(val));
        return MshT(val);
    }

private:
    uint64_t o_;
    uint64_t s_;
};

using VecSegsT = std::vector<MshT>;
using BufferT = std::vector<uint8_t>;

class LinearUtils {
public:
    static std::string MavhToString(uint64_t mavh) {
        std::stringstream out;
        out << MavhT(mavh);
        return out.str();
    }

    static std::string MshToString(uint64_t msh) {
        std::stringstream out;
        out << MshT(msh);
        return out.str();
    }

    static MavhT PrepareFreeSegments(const MavhT& mavh0, uint64_t* pmav_f, const VecSegsT& segs) {
        for (size_t i = 0; i < segs.size(); ++i) {
            const auto seg = segs[i].ToMsh();
            memcpy(pmav_f + i, &seg, sizeof(seg));
        }
        return MavhT(mavh0.MemSz(), mavh0.MavSz(), segs.size(), mavh0.NumUsed());
    }

    static MavhT PrepareUsedSegments(const MavhT& mavh0, uint64_t* pmav_u, const VecSegsT& segs) {
        for (size_t i = 0; i < segs.size(); ++i) {
            const auto seg = segs[i].ToMsh();
            memcpy(pmav_u - i - 1, &seg, sizeof(seg));
        }
        return MavhT(mavh0.MemSz(), mavh0.MavSz(), mavh0.NumFree(), segs.size());
    }

    static void PrintSegments(const MavhT& mavh, const uint8_t* pmem) {
        const auto pmav_f = reinterpret_cast<const uint64_t*>(pmem + mavh.MemSz());
        const auto pmav_u = reinterpret_cast<const uint64_t*>(pmem + mavh.MemSz() + mavh.MavSz());
        std::cout << '\n' << std::string(100, '_') << '\n';
        std::cout << "In memory segments\n";
        std::cout << "pmem = " << std::hex << reinterpret_cast<const uint64_t*>(pmem) << '\n';
        std::cout << std::dec;
        std::cout << mavh << '\n';
        for (size_t i = 0; i < mavh.NumFree(); ++i) {
            std::cout << i << " free " << MshT(*(pmav_f + i)) << '\n';
        }
        for (size_t i = 0; i < mavh.NumUsed(); ++i) {
            std::cout << i << " used " << MshT(*(pmav_u - i - 1)) << '\n';
        }
        std::cout << std::string(100, '-') << '\n';
    }

    static void PrintSegments(const std::string& name, const std::vector<MshT>& mshs) {
        std::cout << '\n' << std::string(100, '_') << '\n';
        std::cout << name << '\n';
        for (size_t i = 0; i < mshs.size(); ++i) {
            std::cout << i << " " << mshs[i] << '\n';
        }
        std::cout << std::string(100, '-') << '\n';
    }

    static void PrintMemory(const MavhT& mavh, const uint8_t* pmem) {
        std::cout << '\n' << std::string(100, '_') << '\n';
        for (size_t i = 0; i < mavh.MemSz(); ++i) {
            const auto c = *(pmem + i);
            if (std::isprint(c)) {
                std::cout << c;
            } else {
                std::cout << '.';
            }
        }
        std::cout << '\n';
    }
};

class LinearTest : public MemoryTestBase {
public:
    LinearTest();
    void SetUp() override;
    void TearDown() override;

    void CheckInited(int line);

    const uint64_t requested_pool_size_;
    const uint64_t effective_pool_size_;
};

LinearTest::LinearTest()
      : requested_pool_size_(2'000'000),
        effective_pool_size_(mem_power_of_2_ceiling(requested_pool_size_)) {}

void LinearTest::SetUp() {
    MemoryTestBase::SetUp();
    EXPECT_EQ(linear_init(requested_pool_size_), 0);
}

void LinearTest::TearDown() {
    linear_deinit();
    MemoryTestBase::TearDown();
}

void LinearTest::CheckInited(int line) {
    SCOPED_TRACE("from line " + std::to_string(line));
    const uint64_t mem_sz = mem_power_of_2_ceiling(requested_pool_size_);
    const uint64_t mav_sz = 4096;

    EXPECT_EQ(_mem_pbase, pool_);

    const MavhT mavh(mem_sz, mav_sz, 1, 0);
    EXPECT_EQ(MavhT(_linear_mavh), mavh);

    // when memory is allocated it is filled with '-'
    for (size_t i = 0; i < mem_sz; ++i) {
        EXPECT_EQ(pool_[i], '-') << "at offset " << i;
    }
    for (size_t i = 8; i < mav_sz; ++i) { // 8 to skip first free MSH that is filled
        EXPECT_EQ(pool_[mem_sz + i], '-') << "at offset " << i;
    }

    // check the first MSH
    const auto pmav_f = reinterpret_cast<const uint64_t*>(pool_ + mem_sz);
    const MshT msh(0, mem_sz);
    EXPECT_EQ(MshT(*pmav_f), msh);
}

TEST_F(LinearTest, inited) {
    // it was inited in constructor
    CheckInited(__LINE__);
}

TEST_F(LinearTest, init_a_second_time_return_error) {
    EXPECT_EQ(linear_init(150'000), -EBUSY);
    CheckInited(__LINE__);
}

TEST_F(LinearTest, deinit) {
    linear_deinit();
    EXPECT_EQ(_linear_mavh, 0);
}

TEST_F(LinearTest, allocate) {
    const MavhT mavh0(_linear_mavh);
    auto expected_ptr = pool_ + mavh0.MemSz() - 64;
    EXPECT_EQ(linear_allocate(64), expected_ptr);
    const MavhT mavh1(_linear_mavh);
    EXPECT_EQ(mavh1.MemSz(), mavh0.MemSz());
    EXPECT_EQ(mavh1.MavSz(), mavh0.MavSz());
    EXPECT_EQ(mavh1.NumFree(), mavh0.NumFree());
    EXPECT_EQ(mavh1.NumUsed(), mavh0.NumUsed() + 1);

    auto msh_f = MshT::GetAt(pool_, mavh0.MemSz());
    auto msh_u_0 = MshT::GetAt(pool_, mavh0.FullSz() - 8);

    EXPECT_EQ(msh_f, MshT(0, mavh0.MemSz() - 64));
    EXPECT_EQ(msh_u_0, MshT(mavh0.MemSz() - 64, 64));

    // allocate another block
    expected_ptr = pool_ + mavh0.MemSz() - 64 - 512;
    EXPECT_EQ(linear_allocate(512), expected_ptr);
    const MavhT mavh2(_linear_mavh);
    EXPECT_EQ(mavh2.MemSz(), mavh0.MemSz());
    EXPECT_EQ(mavh2.MavSz(), mavh0.MavSz());
    EXPECT_EQ(mavh2.NumFree(), mavh0.NumFree());
    EXPECT_EQ(mavh2.NumUsed(), mavh0.NumUsed() + 2);

    msh_f = MshT::GetAt(pool_, mavh0.MemSz());
    msh_u_0 = MshT::GetAt(pool_, mavh0.FullSz() - 8);
    auto msh_u_1 = MshT::GetAt(pool_, mavh0.FullSz() - 16);

    EXPECT_EQ(msh_f, MshT(0, mavh0.MemSz() - 64 - 512));
    EXPECT_EQ(msh_u_0, MshT(mavh0.MemSz() - 64 - 512, 512));
    EXPECT_EQ(msh_u_1, MshT(mavh0.MemSz() - 64, 64));
}

TEST_F(LinearTest, allocate_until_resize_mavh) {
    const MavhT mavh0(_linear_mavh);
    constexpr uint64_t ALLOC_SZ = 16;
    auto expected_ptr = _mem_pbase + mavh0.MemSz();
    auto num_used = mavh0.NumUsed();
    for (size_t i = 0; i < 511; ++i) {
        SCOPED_TRACE("Allocation " + std::to_string(i));
        expected_ptr -= ALLOC_SZ;
        num_used += 1;
        auto expected_mavh = MavhT(mavh0.MemSz(), mavh0.MavSz(), mavh0.NumFree(), num_used);
        EXPECT_EQ(linear_allocate(ALLOC_SZ), expected_ptr);
        EXPECT_EQ(MavhT(_linear_mavh), expected_mavh);
    }

    expected_ptr -= ALLOC_SZ;
    num_used += 1;
    const auto mavh1 = MavhT(mavh0.MemSz(), mavh0.MavSz() * 2, mavh0.NumFree(), num_used);
    EXPECT_EQ(linear_allocate(ALLOC_SZ), expected_ptr);
    EXPECT_EQ(MavhT(_linear_mavh), mavh1);

    // check that all msh were copied
    auto expected_offset = mavh0.MemSz() - 512 * ALLOC_SZ;
    auto pmsh = reinterpret_cast<uint64_t*>(_mem_pbase + mavh1.FullSz());

    for (size_t i = 0; i < 512; ++i) {
        SCOPED_TRACE("Verification " + std::to_string(i));
        pmsh -= 1;
        MshT expected_msh(expected_offset, ALLOC_SZ);
        EXPECT_EQ(MshT(*pmsh), expected_msh);
        expected_offset += ALLOC_SZ;
    }
}

TEST_F(LinearTest, allocate_until_remove_msh) {
    const MavhT mavh0(_linear_mavh);
    const auto alloc_size = mavh0.MemSz() / 2;

    auto expected_ptr = pool_ + mavh0.MemSz() - alloc_size;
    EXPECT_EQ(linear_allocate(alloc_size), expected_ptr);
    const MavhT mavh1(_linear_mavh);
    EXPECT_EQ(mavh1.MemSz(), mavh0.MemSz());
    EXPECT_EQ(mavh1.MavSz(), mavh0.MavSz());
    EXPECT_EQ(mavh1.NumFree(), mavh0.NumFree());
    EXPECT_EQ(mavh1.NumUsed(), mavh0.NumUsed() + 1);

    auto msh_f = MshT::GetAt(pool_, mavh0.MemSz());
    auto msh_u = MshT::GetAt(pool_, mavh0.FullSz() - 8);

    EXPECT_EQ(msh_f, MshT(0, mavh0.MemSz() - alloc_size));
    EXPECT_EQ(msh_u, MshT(mavh0.MemSz() - alloc_size, alloc_size));

    // allocate the rest of the memory (will remove the free msh)

    expected_ptr = pool_;
    EXPECT_EQ(linear_allocate(alloc_size), expected_ptr);
    const MavhT mavh2(_linear_mavh);
    EXPECT_EQ(mavh2.MemSz(), mavh0.MemSz());
    EXPECT_EQ(mavh2.MavSz(), mavh0.MavSz());
    EXPECT_EQ(mavh2.NumFree(), mavh0.NumFree() - 1);
    EXPECT_EQ(mavh2.NumUsed(), mavh0.NumUsed() + 2);

    msh_u = MshT::GetAt(pool_, mavh0.FullSz() - 8);

    EXPECT_EQ(msh_u, MshT(0, alloc_size));
}

TEST_F(LinearTest, allocate_filled) {
    const MavhT mavh0(_linear_mavh);
    auto expected_ptr = pool_ + mavh0.MemSz() - 64;
    EXPECT_EQ(linear_allocate_filled(64, '+'), expected_ptr);
    const MavhT mavh1(_linear_mavh);
    EXPECT_EQ(mavh1.MemSz(), mavh0.MemSz());
    EXPECT_EQ(mavh1.MavSz(), mavh0.MavSz());
    EXPECT_EQ(mavh1.NumFree(), mavh0.NumFree());
    EXPECT_EQ(mavh1.NumUsed(), mavh0.NumUsed() + 1);

    auto msh_f = MshT::GetAt(pool_, mavh0.MemSz());
    auto msh_u_0 = MshT::GetAt(pool_, mavh0.FullSz() - 8);

    EXPECT_EQ(msh_f, MshT(0, mavh0.MemSz() - 64));
    EXPECT_EQ(msh_u_0, MshT(mavh0.MemSz() - 64, 64));

    for (size_t i = 0; i < 64; ++i) {
        EXPECT_EQ(expected_ptr[i], '+') << "for " << i;
    }
}

TEST_F(LinearTest, deallocate_non_allocated) {
    EXPECT_NE(linear_deallocate(_mem_pbase), 0);
}

void PrepareMemoryAllocation(
      MavhT& mavh,
      uint8_t* buffer,
      VecSegsT& free_segs,
      const VecSegsT& used_segs) {
    uint64_t offset = 0;
    free_segs.clear();
    for (auto used_seg : used_segs) {
        const MshT seg(used_seg);
        free_segs.emplace_back(offset, seg.Offset() - offset);
        offset = seg.Offset() + seg.Size();
    }
    free_segs.emplace_back(offset, mavh.MemSz() - offset);
    const auto pmav_f = reinterpret_cast<uint64_t*>(buffer + mavh.MemSz());
    const auto pmav_u = reinterpret_cast<uint64_t*>(buffer + mavh.MemSz() + mavh.MavSz());
    LinearUtils::PrepareFreeSegments(mavh, pmav_f, free_segs);
    LinearUtils::PrepareUsedSegments(mavh, pmav_u, used_segs);
    mavh = MavhT(mavh.MemSz(), mavh.MavSz(), free_segs.size(), used_segs.size());
}

void CheckMemoryAllocation(
      int line,
      const MavhT& mavh,
      const uint8_t* buffer,
      const VecSegsT& free_segs,
      const VecSegsT& used_segs) {
    SCOPED_TRACE("From line " + std::to_string(line) + " / " + mavh.ToString());
    EXPECT_EQ(mavh.NumFree(), free_segs.size());
    EXPECT_EQ(mavh.NumUsed(), used_segs.size());
    const auto pmav_f = reinterpret_cast<const uint64_t*>(buffer + mavh.MemSz());
    const auto pmav_u = reinterpret_cast<const uint64_t*>(buffer + mavh.MemSz() + mavh.MavSz());
    for (size_t i = 0; i < free_segs.size(); ++i) {
        const uint64_t* pmsh = pmav_f + i;
        EXPECT_EQ(free_segs[i], MshT(*pmsh)) << "free " << i;
    }
    for (size_t i = 0; i < used_segs.size(); ++i) {
        const uint64_t* pmsh = pmav_u - i - 1;
        EXPECT_EQ(used_segs[i], MshT(*pmsh)) << "used " << i;
    }
}

TEST_F(LinearTest, deallocate_manual) {
    MavhT mavh(_linear_mavh);
    VecSegsT used_segs = {
        MshT(128, 32),
        MshT(256, 64),
        MshT(1024, 512),
    };
    VecSegsT free_segs;
    PrepareMemoryAllocation(mavh, _mem_pbase, free_segs, used_segs);
    _linear_mavh = mavh.ToMavh();

    CheckMemoryAllocation(__LINE__, mavh, _mem_pbase, free_segs, used_segs);

    while (not used_segs.empty()) {
        linear_deallocate(_mem_pbase + used_segs[0].Offset());
        free_segs[0] =
              MshT(free_segs[0].Offset(),
                   free_segs[0].Size() + free_segs[1].Size() + used_segs[0].Size());
        free_segs.erase(free_segs.begin() + 1);
        used_segs.erase(used_segs.begin());
        mavh = MavhT(mavh.MemSz(), mavh.MavSz(), free_segs.size(), used_segs.size());
        CheckMemoryAllocation(__LINE__, mavh, _mem_pbase, free_segs, used_segs);
    }
}

bool OrderByOffset(const MshT& x, const MshT& y) {
    return x.Offset() < y.Offset();
}

void InsertSorted(std::vector<MshT>& mshs, const MshT& msh) {
    auto after = std::lower_bound(mshs.begin(), mshs.end(), msh, OrderByOffset);
    mshs.insert(after, msh);
}

void ReduceFreeSpace(std::vector<MshT>& mshs, const MshT& msh) {
    auto it = std::find_if(mshs.begin(), mshs.end(), [&msh](const auto& it) {
        return it.Offset() + it.Size() == msh.Offset() + msh.Size();
    });

    if (it != mshs.end()) {
        it->ReduceSize(msh);
        if (it->Size() == 0) {
            mshs.erase(it);
        }
    }
}

void IncreaseFreeSpace(std::vector<MshT>& mshs, const MshT& msh) {
    auto it = std::find_if(mshs.begin(), mshs.end(), [&msh](const auto& it) {
        return it.Offset() + it.Size() >= msh.Offset();
    });
    if (it == mshs.end()) {
        mshs.push_back(msh);
    } else {
        if (it->FollowedBy(msh)) {
            it->IncreaseSize(msh);
            auto next = std::next(it);
            if (next != mshs.end() && it->FollowedBy(*next)) {
                it->IncreaseSize(*next);
                mshs.erase(next);
            }
        } else if (msh.FollowedBy(*it)) {
            *it = MshT(msh.Offset(), msh.Size() + it->Size());
        } else {
            mshs.insert(it, msh);
        }
    }
}

TEST_F(LinearTest, allocate_and_deallocate) {
    constexpr uint64_t mem_sz = 0x1'0000;
    constexpr uint64_t mav_sz = 0x1000;
    const MavhT mavh0(mem_sz, mav_sz, 1, 0);
    const MshT msh0(0, mem_sz);
    _linear_mavh = mavh0.ToMavh();
    uint64_t* const pmav_f = reinterpret_cast<uint64_t*>(_mem_pbase + mem_sz);
    const uint64_t* pmav_u = reinterpret_cast<const uint64_t*>(_mem_pbase + mem_sz + mav_sz);
    *pmav_f = msh0.ToMsh();
    std::vector<const void*> allocated;
    std::vector<MshT> used;
    std::vector<MshT> free = { msh0 };

    for (size_t i = 0; i < 10'000; ++i) {
        SCOPED_TRACE("Iteration " + std::to_string(i));
        const auto is_allocate = Utils::RandomValue<size_t>(0, 10);
        if (is_allocate <= 7) {
            const auto size = Utils::RandomValue<size_t>(1, 50) * 8;
            const char c = (i % 26) + 'a';
            const auto addr = linear_allocate_filled(size, c);
            if (addr != nullptr) {
                allocated.push_back(addr);
                std::sort(allocated.begin(), allocated.end());
                const MshT msh(reinterpret_cast<const uint8_t*>(addr) - _mem_pbase, size);
                InsertSorted(used, msh);
                ReduceFreeSpace(free, msh);
            }
        } else {
            if (not allocated.empty()) {
                const auto idx = Utils::RandomValue<size_t>(0, allocated.size() - 1);
                const auto msh_u = used[idx];
                std::memset(_mem_pbase + msh_u.Offset(), '-', msh_u.Size());
                const auto res = linear_deallocate(allocated.at(idx));
                EXPECT_EQ(res, 0) << idx << " -- " << allocated.at(idx) << " -- "
                                  << (const uint8_t*) allocated.at(idx) - _mem_pbase;
                if (res != 0) {
                    break;
                }
                allocated.erase(allocated.begin() + idx);
                used.erase(used.begin() + idx);
                IncreaseFreeSpace(free, msh_u);
            }
        }

        // check the free and the used MSHs
        const MavhT mavh(_linear_mavh);
        pmav_u = reinterpret_cast<const uint64_t*>(_mem_pbase + mavh.MemSz() + mavh.MavSz());
        std::vector<MshT> mav_f, mav_u;
        for (size_t i = 0; i < mavh.NumFree(); ++i) {
            mav_f.emplace_back(*(pmav_f + i));
        }

        for (size_t i = 0; i < mavh.NumUsed(); ++i) {
            mav_u.emplace_back(*(pmav_u - i - 1));
        }
        EXPECT_EQ(mav_f, free) << mavh;
        EXPECT_EQ(mav_u, used) << mavh;
    }
}

TEST_F(LinearTest, get_mav_size) {
    // 6 bits [52-57]
    EXPECT_EQ(_linear_get_mav_size(0x0000'0000'0000'0000), 1);
    EXPECT_EQ(_linear_get_mav_size(0x0010'0000'0000'0000), 2);
    EXPECT_EQ(_linear_get_mav_size(0x0020'0000'0000'0000), 4);
    EXPECT_EQ(_linear_get_mav_size(0x0030'0000'0000'0000), 8);
    EXPECT_EQ(_linear_get_mav_size(0x0040'0000'0000'0000), 16);
    EXPECT_EQ(_linear_get_mav_size(0x0050'0000'0000'0000), 32);
    EXPECT_EQ(_linear_get_mav_size(0x0060'0000'0000'0000), 64);
    for (uint64_t power = 0; power < 32; ++power) {
        uint64_t mavh = Utils::RandomValue<uint64_t>();
        mavh &= 0xfc0f'ffff'ffff'ffff;
        mavh |= power << 52;
        const uint64_t size = uint64_t(1) << power;
        EXPECT_EQ(_linear_get_mav_size(mavh), size) << LinearUtils::MavhToString(mavh);
    }
}

TEST_F(LinearTest, get_memory_size) {
    // top 6 bits [58-63]
    EXPECT_EQ(_linear_get_memory_size(0x0000'0000'0000'0000), 1);
    EXPECT_EQ(_linear_get_memory_size(0x0400'0000'0000'0000), 2);
    EXPECT_EQ(_linear_get_memory_size(0x0800'0000'0000'0000), 4);
    EXPECT_EQ(_linear_get_memory_size(0x0c00'0000'0000'0000), 8);
    EXPECT_EQ(_linear_get_memory_size(0x1000'0000'0000'0000), 16);
    EXPECT_EQ(_linear_get_memory_size(0x1400'0000'0000'0000), 32);
    EXPECT_EQ(_linear_get_memory_size(0x1800'0000'0000'0000), 64);
    for (uint64_t power = 0; power < 64; ++power) {
        uint64_t mavh = Utils::RandomValue<uint64_t>();
        mavh &= 0x03ff'ffff'ffff'ffff;
        mavh |= power << 58;
        const uint64_t size = uint64_t(1) << power;
        EXPECT_EQ(_linear_get_memory_size(mavh), size) << LinearUtils::MavhToString(mavh);
    }
}

TEST_F(LinearTest, get_number_of_free_segment_headers) {
    // 26 bits (26-51)
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'0000'0000'0000), 0);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'0000'0400'0000), 1);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'0000'0800'0000), 2);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'000f'fc00'0000), 1023);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'00ff'fc00'0000), 16'383);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'0fff'fc00'0000), 262'143);
    EXPECT_EQ(_linear_get_number_of_free_segment_headers(0x0000'ffff'fc00'0000), 4'194'303);
    EXPECT_EQ(
          _linear_get_number_of_free_segment_headers(0x000f'ffff'fc00'0000),
          67'108'863); // maximum
    for (uint64_t bits = 1; bits <= 26; ++bits) {
        uint64_t mavh = Utils::RandomValue<uint64_t>();
        mavh &= 0xfff0'0000'03ff'ffff;
        const uint64_t size = (uint64_t(1) << bits) - 1;
        mavh |= size << 26;
        EXPECT_EQ(_linear_get_number_of_free_segment_headers(mavh), size)
              << LinearUtils::MavhToString(mavh);
    }
}

TEST_F(LinearTest, get_number_of_used_segment_headers) {
    // 26 bits (0-25)
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'0000'0000), 0);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'0000'000f), 15);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'0000'00ff), 255);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'0000'0fff), 4'095);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'0000'ffff), 65'535);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'000f'ffff), 1'048'575);
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'00ff'ffff), 16'777'215);
    // maximum
    EXPECT_EQ(_linear_get_number_of_used_segment_headers(0x0000'0000'03ff'ffff), 67'108'863);
    for (uint64_t bits = 1; bits <= 26; ++bits) {
        uint64_t mavh = Utils::RandomValue<uint64_t>();
        mavh &= 0xffff'ffff'fc00'0000;
        const uint64_t size = (uint64_t(1) << bits) - 1;
        mavh |= size;
        EXPECT_EQ(_linear_get_number_of_used_segment_headers(mavh), size)
              << LinearUtils::MavhToString(mavh);
    }
}

TEST_F(LinearTest, set_mavh) {
    EXPECT_EQ(_linear_set_mavh(0x1000'0000, 0x1000, 2, 3), 0x70c0'0000'0800'0003);
}

TEST_F(LinearTest, set_segment_header) {
    EXPECT_EQ(_linear_set_msh(0x4'1234'5678, 0x4'9876'5438), 0x8246'8acf'930e'ca87);

    // maximum
    EXPECT_EQ(_linear_set_msh(0x7'ffff'fff8, 0x7'ffff'fff8), 0xffff'ffff'ffff'ffff);

    // maximum cleaning unused bits
    EXPECT_EQ(_linear_set_msh(0xf'ffff'ffff, 0xf'ffff'ffff), 0xffff'ffff'ffff'ffff);
}

TEST_F(LinearTest, reduce_free_space) {
    constexpr uint64_t offset = 0xfff230;
    constexpr uint64_t size = 0xfff10;
    const auto msh0 = _linear_set_msh(offset, size);
    EXPECT_EQ(_linear_reduce_free_space(msh0, 16), _linear_set_msh(offset, size - 16));
    EXPECT_EQ(_linear_reduce_free_space(msh0, 160), _linear_set_msh(offset, size - 160));
    for (uint64_t sz = 24; sz <= size; sz += 16) {
        SCOPED_TRACE("for size " + std::to_string(sz));
        const auto reduced = _linear_reduce_free_space(msh0, sz);
        const auto expected = _linear_set_msh(offset, size - sz);
        EXPECT_EQ(MshT(reduced), MshT(expected));
    }
}

TEST_F(LinearTest, find_free_segment) {
    const MavhT mavh(_linear_mavh);
    EXPECT_EQ(
          _linear_find_free_msh(_linear_mavh, _mem_pbase, 256),
          reinterpret_cast<uint64_t*>(_mem_pbase + mavh.MemSz()));
    EXPECT_EQ(_linear_find_free_msh(_linear_mavh, _mem_pbase, effective_pool_size_ + 8), nullptr);
}

TEST_F(LinearTest, find_free_segment_manual_buffer) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    uint8_t buffer[mem_sz + mav_sz];
    uint64_t* const pmav_f = reinterpret_cast<uint64_t*>(buffer + mem_sz);
    const VecSegsT segs = {
        MshT(0, 16),
        MshT(128, 32),
        MshT(256, 64),
        MshT(1024, 512),
    };
    const auto mavh = LinearUtils::PrepareFreeSegments(MavhT(mem_sz, mav_sz, 0, 0), pmav_f, segs);

    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 8), pmav_f + 0);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 16), pmav_f + 0);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 24), pmav_f + 1);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 32), pmav_f + 1);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 40), pmav_f + 2);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 64), pmav_f + 2);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 512), pmav_f + 3);
    EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, 520), nullptr);
    for (uint64_t sz = 8; sz <= 512; sz += 8) {
        auto index = [&segs](const uint64_t size) -> size_t {
            for (size_t i = 0; i < segs.size(); ++i) {
                if (size <= segs[i].Size()) {
                    return i;
                }
            }
            return segs.size();
        };
        EXPECT_EQ(_linear_find_free_msh(mavh.ToMavh(), buffer, sz), pmav_f + index(sz));
    }
}

TEST_F(LinearTest, find_used_segment) {
    const MavhT mavh(_linear_mavh);
    for (size_t offset = 0; offset < mavh.MemSz(); offset += 8) {
        EXPECT_EQ(_linear_find_used_msh(_linear_mavh, _mem_pbase, _mem_pbase + offset), nullptr);
    }
}

TEST_F(LinearTest, find_used_segment_manual_buffer) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    uint8_t buffer[mem_sz + mav_sz];
    uint64_t* const pmav_u = reinterpret_cast<uint64_t*>(buffer + mem_sz + mav_sz);
    const VecSegsT segs = {
        MshT(0, 16),
        MshT(128, 32),
        MshT(256, 64),
        MshT(1024, 512),
    };
    const auto mavh = LinearUtils::PrepareUsedSegments(MavhT(mem_sz, mav_sz, 0, 0), pmav_u, segs);
    for (size_t i = 0; i < segs.size(); ++i) {
        SCOPED_TRACE("Seg = " + segs[i].ToString());
        EXPECT_EQ(
              _linear_find_used_msh(mavh.ToMavh(), buffer, buffer + segs[i].Offset()),
              pmav_u - i);
    }
    // try address that don't match
    for (const auto& seg : segs) {
        SCOPED_TRACE("Seg = " + seg.ToString());
        EXPECT_EQ(_linear_find_used_msh(mavh.ToMavh(), buffer, buffer + seg.Offset() + 8), nullptr);
    }
}

TEST_F(LinearTest, find_index_new_free_segment) {
    const MavhT mavh(_linear_mavh);
    EXPECT_EQ(_linear_find_index_new_free_msh(_linear_mavh, _mem_pbase, 128), 1);
}

TEST_F(LinearTest, find_index_new_free_segment_manual_buffer) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    uint8_t buffer[mem_sz + mav_sz];
    const auto pmav_f = reinterpret_cast<uint64_t*>(buffer + mem_sz);

    VecSegsT segs = {
        MshT(0, 64),
        MshT(512, 16),
        MshT(1024, 32),
        MshT(1064, 64),
    };
    const auto mavh = LinearUtils::PrepareFreeSegments(MavhT(mem_sz, mav_sz, 0, 0), pmav_f, segs);
    EXPECT_EQ(_linear_find_index_new_free_msh(mavh.ToMavh(), buffer, 4096), segs.size());
    uint64_t expected_msh = 0;
    for (uint64_t offset = 0; offset < 1600; offset += 8) {
        SCOPED_TRACE(
              "offset = " + std::to_string(offset) + " / expected_msh "
              + std::to_string(expected_msh));
        if (expected_msh < segs.size() && offset == segs[expected_msh].Offset()) {
            ++expected_msh;
            continue;
        }
        EXPECT_EQ(_linear_find_index_new_free_msh(mavh.ToMavh(), buffer, offset), expected_msh);
    }
}

TEST_F(LinearTest, find_index_new_free_segment_manual_buffer_no_free_segments) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    uint8_t buffer[mem_sz + mav_sz];
    const auto mavh = _linear_set_mavh(mem_sz, mav_sz, 0, 0);
    for (uint64_t offset = 0; offset < 1600; offset += 8) {
        SCOPED_TRACE("offset = " + std::to_string(offset));
        EXPECT_EQ(_linear_find_index_new_free_msh(mavh, buffer, offset), 0);
    }
}

TEST_F(LinearTest, find_position_new_used_segment) {
    const MavhT mavh(_linear_mavh);
    EXPECT_EQ(
          _linear_find_position_new_used_msh(_linear_mavh, _mem_pbase, 0),
          reinterpret_cast<uint64_t*>(_mem_pbase + mavh.MemSz() + mavh.MavSz()));
}

TEST_F(LinearTest, find_position_new_used_segment_manual_buffer) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    uint8_t buffer[mem_sz + mav_sz];
    const auto pmav_u = reinterpret_cast<uint64_t*>(buffer + mem_sz + mav_sz);
    VecSegsT segs = {
        MshT(512, 16),
        MshT(1024, 32),
        MshT(1064, 64),
        MshT(2048, 512),
    };
    const auto mavh = LinearUtils::PrepareUsedSegments(MavhT(mem_sz, mav_sz, 0, 0), pmav_u, segs);
    EXPECT_EQ(
          _linear_find_position_new_used_msh(mavh.ToMavh(), buffer, 4096),
          pmav_u - segs.size());
    uint64_t expected_msh = 0;
    for (uint64_t offset = 0; offset < 2560; offset += 8) {
        SCOPED_TRACE(
              "offset = " + std::to_string(offset) + " / expected_msh "
              + std::to_string(expected_msh));
        if (expected_msh < segs.size() && offset == segs[expected_msh].Offset()) {
            ++expected_msh;
            continue;
        }
        EXPECT_EQ(
              _linear_find_position_new_used_msh(mavh.ToMavh(), buffer, offset),
              pmav_u - expected_msh);
    }
}

void CheckLinearInsertFreeSegment(
      int line,
      uint64_t mem_sz,
      uint64_t mav_sz,
      const VecSegsT& segs_before,
      const MshT& msh,
      const VecSegsT& segs_after) {
    SCOPED_TRACE("From line " + std::to_string(line));
    const auto full_sz = mem_sz + mav_sz;
    BufferT buffer(full_sz, 0);
    const auto pmav_f = reinterpret_cast<uint64_t*>(buffer.data() + mem_sz);

    const auto mavh =
          LinearUtils::PrepareFreeSegments(MavhT(mem_sz, mav_sz, 0, 0), pmav_f, segs_before);

    // check initial situation of buffer
    for (size_t i = 0; i < mem_sz; ++i) {
        EXPECT_EQ(buffer[i], 0) << "offset " << i;
    }
    for (size_t i = segs_before.size() * 8; i < mav_sz; ++i) {
        EXPECT_EQ(buffer[mem_sz + i], 0) << "offset " << i;
    }
    for (size_t i = 0; i < segs_before.size(); ++i) {
        const auto sh = pmav_f[i];
        EXPECT_EQ(MshT(sh), MshT(segs_before[i])) << "offset " << i;
    }

    // make the change
    const auto new_mavh = _linear_insert_free_msh(mavh.ToMavh(), buffer.data(), msh.ToMsh());

    // check buffer situation after change
    EXPECT_EQ(MavhT(new_mavh), MavhT(_linear_set_mavh(mem_sz, mav_sz, segs_after.size(), 0)));
    // check final situation of buffer
    for (size_t i = 0; i < mem_sz; ++i) {
        EXPECT_EQ(buffer[i], 0) << "offset " << i;
    }
    for (size_t i = std::max(segs_before.size(), segs_after.size()) * 8; i < mav_sz; ++i) {
        EXPECT_EQ(buffer[mem_sz + i], 0) << "offset " << i;
    }
    for (size_t i = 0; i < segs_after.size(); ++i) {
        const auto sh = pmav_f[i];
        EXPECT_EQ(MshT(sh), MshT(segs_after[i])) << "idx " << i;
    }
}

TEST_F(LinearTest, insert_free_segment) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    MshT msh(0);
    const VecSegsT segs0 = { MshT(512, 16), MshT(1024, 32), MshT(2048, 64) };
    VecSegsT segs1;

    // inserting a new MSH
    msh = MshT(256, 32);
    segs1 = { msh, segs0[0], segs0[1], segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(640, 32);
    segs1 = { segs0[0], msh, segs0[1], segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(1600, 32);
    segs1 = { segs0[0], segs0[1], msh, segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(2400, 32);
    segs1 = { segs0[0], segs0[1], segs0[2], msh };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);

    // joining behind
    msh = MshT(528, 32);
    segs1 = { MshT(512, 48), segs0[1], segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(1056, 32);
    segs1 = { segs0[0], MshT(1024, 64), segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(2112, 32);
    segs1 = { segs0[0], segs0[1], MshT(2048, 96) };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);

    // joining ahead
    msh = MshT(256, 256);
    segs1 = { MshT(256, 272), segs0[1], segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(1000, 24);
    segs1 = { segs0[0], MshT(1000, 56), segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(2000, 48);
    segs1 = { segs0[0], segs0[1], MshT(2000, 112) };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);

    // joining ahead and behind
    msh = MshT(528, 496);
    segs1 = { MshT(512, 544), segs0[2] };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
    msh = MshT(1056, 992);
    segs1 = { segs0[0], MshT(1024, 1088) };
    CheckLinearInsertFreeSegment(__LINE__, mem_sz, mav_sz, segs0, msh, segs1);
}

void CheckLinearInsertUsedSegment(
      uint64_t mem_sz,
      uint64_t mav_sz,
      VecSegsT segs,
      const MshT& msh,
      uint64_t insert_idx) {
    const auto full_sz = mem_sz + mav_sz;
    BufferT buffer(full_sz, 0);
    std::generate(buffer.begin(), buffer.end(), []() { return Utils::RandomValue<uint8_t>(); });
    const auto buffer0 = buffer; // save a copy

    const auto pmav_u = reinterpret_cast<uint64_t*>(buffer.data() + full_sz);

    const auto mavh = LinearUtils::PrepareUsedSegments(MavhT(mem_sz, mav_sz, 1, 0), pmav_u, segs);

    // check initial situation of buffer
    for (size_t i = 0; i < full_sz - 8 * segs.size(); ++i) {
        EXPECT_EQ(buffer[i], buffer0[i]) << i;
    }
    for (size_t i = 0; i < segs.size(); ++i) {
        const auto sh = *(pmav_u - (i + 1));
        EXPECT_EQ(MshT(sh), segs[i]) << i;
    }

    // make the change
    const auto new_mavh = _linear_insert_used_msh(mavh.ToMavh(), buffer.data(), msh.ToMsh());
    segs.insert(segs.begin() + insert_idx, msh);

    EXPECT_EQ(new_mavh, _linear_set_mavh(mem_sz, mav_sz, 1, segs.size()));
    // check buffer situation after change
    for (size_t i = 0; i < full_sz - 8 * segs.size(); ++i) {
        EXPECT_EQ(buffer[i], buffer0[i]) << i;
    }
    for (size_t i = 0; i < segs.size(); ++i) {
        const auto sh = *(pmav_u - (i + 1));
        EXPECT_EQ(MshT(sh), segs[i]) << i;
    }
}

TEST_F(LinearTest, insert_used_segment) {
    constexpr uint64_t mem_sz = 0x8'0000;
    constexpr uint64_t mav_sz = 0x1000;
    VecSegsT segs = {
        MshT(512, 16),
        MshT(1024, 32),
        MshT(1064, 64),
        MshT(2048, 512),
    };

    auto msh = MshT(256, 32);
    CheckLinearInsertUsedSegment(mem_sz, mav_sz, segs, msh, 0);
    msh = MshT(640, 32);
    CheckLinearInsertUsedSegment(mem_sz, mav_sz, segs, msh, 1);
    msh = MshT(1056, 32);
    CheckLinearInsertUsedSegment(mem_sz, mav_sz, segs, msh, 2);
    msh = MshT(1128, 32);
    CheckLinearInsertUsedSegment(mem_sz, mav_sz, segs, msh, 3);
    msh = MshT(2560, 32);
    CheckLinearInsertUsedSegment(mem_sz, mav_sz, segs, msh, 4);
}

TEST_F(LinearTest, remove_free_segment) {
    constexpr uint64_t NUM_FREE_SEGMENTS = 10;
    constexpr uint64_t IDX_REMOVE = 6;
    const MavhT mavh0(_linear_mavh);
    // change mavh to get
    _linear_mavh = _linear_set_mavh(mavh0.MemSz(), mavh0.MavSz(), NUM_FREE_SEGMENTS, 5);
    // fill free segment headers with random bytes
    auto pmav_f = _mem_pbase + mavh0.MemSz();
    std::generate(pmav_f, pmav_f + mavh0.MavSz(), []() { return Utils::RandomValue<uint8_t>(); });
    BufferT expected_mav;
    std::copy_n(pmav_f, mavh0.MavSz(), std::back_inserter(expected_mav));
    const auto begin = expected_mav.begin();
    std::copy(begin + (IDX_REMOVE + 1) * 8, begin + NUM_FREE_SEGMENTS * 8, begin + IDX_REMOVE * 8);

    const MavhT expected_mavh(mavh0.MemSz(), mavh0.MavSz(), NUM_FREE_SEGMENTS - 1, 5);
    auto pmsh = reinterpret_cast<uint64_t*>(pmav_f + IDX_REMOVE * 8);
    EXPECT_EQ(MavhT(_linear_remove_free_msh(_linear_mavh, _mem_pbase, pmsh)), expected_mavh);

    for (size_t i = 0; i < expected_mav.size(); ++i) {
        EXPECT_EQ(expected_mav[i], pmav_f[i]) << "for " << i;
    }
}

TEST_F(LinearTest, remove_used_segment) {
    constexpr uint64_t NUM_USED_SEGMENTS = 10;
    constexpr uint64_t IDX_REMOVE = 6;
    const MavhT mavh0(_linear_mavh);
    // change mavh to simulate allocations
    _linear_mavh = _linear_set_mavh(mavh0.MemSz(), mavh0.MavSz(), 5, NUM_USED_SEGMENTS);
    // fill free segment headers with random bytes
    auto pmav_f = _mem_pbase + mavh0.MemSz();
    auto pmav_u = pmav_f + mavh0.MavSz();
    std::generate(pmav_f, pmav_f + mavh0.MavSz(), []() { return Utils::RandomValue<uint8_t>(); });
    BufferT expected_mav;
    std::copy_n(pmav_f, mavh0.MavSz(), std::back_inserter(expected_mav));
    const auto begin = expected_mav.end() - NUM_USED_SEGMENTS * 8;
    const auto end = expected_mav.end() - IDX_REMOVE * 8 - 8;
    const auto end_d = end + 8;
    std::copy_backward(begin, end, end_d);

    const MavhT expected_mavh(mavh0.MemSz(), mavh0.MavSz(), 5, NUM_USED_SEGMENTS - 1);
    auto pmsh = reinterpret_cast<uint64_t*>(pmav_u - IDX_REMOVE * 8);
    EXPECT_EQ(MavhT(_linear_remove_used_msh(_linear_mavh, _mem_pbase, pmsh)), expected_mavh);

    for (size_t i = 0; i < expected_mav.size(); ++i) {
        EXPECT_EQ(expected_mav[i], pmav_f[i]) << "for " << i;
    }
}

TEST_F(LinearTest, expand_mav_if_necessary) {
    const MavhT mavh0(_linear_mavh);
    // It won't expand MAV
    EXPECT_EQ(_linear_expand_mav_if_necessary(_linear_mavh, _mem_pbase), _linear_mavh);
    EXPECT_EQ(mavh0, MavhT(_linear_mavh));

    // Manipulate mavh to almost full
    uint8_t* pmav_f = _mem_pbase + mavh0.MemSz();
    uint8_t* pmav_u = pmav_f + mavh0.MavSz();

    auto manipulated = _linear_set_mavh(mavh0.MemSz(), mavh0.MavSz(), 256, 255);
    EXPECT_EQ(_linear_expand_mav_if_necessary(manipulated, _mem_pbase), manipulated);
    EXPECT_EQ(mavh0, MavhT(_linear_mavh));

    constexpr uint64_t num_mavu_bytes = 256 * 8;
    auto begin_mavu = pmav_u - num_mavu_bytes;
    auto begin_new_mavu = pmav_u + mavh0.MavSz() - num_mavu_bytes;

    // fill used segment headers with random bytes
    std::generate_n(begin_mavu, num_mavu_bytes, []() { return Utils::RandomValue<uint8_t>(); });
    // Manipulate mavh to full
    manipulated = _linear_set_mavh(mavh0.MemSz(), mavh0.MavSz(), 256, 256);
    auto expanded = _linear_set_mavh(mavh0.MemSz(), mavh0.MavSz() * 2, 256, 256);
    EXPECT_EQ(_linear_expand_mav_if_necessary(manipulated, _mem_pbase), expanded);
    EXPECT_EQ(MavhT(_linear_mavh), mavh0);

    EXPECT_EQ(memcmp(begin_mavu, begin_new_mavu, num_mavu_bytes), 0);
}

TEST_F(LinearTest, block_offset) {
    EXPECT_EQ(_linear_block_offset(0x0000'0000'0000'0000), 0);
    EXPECT_EQ(_linear_block_offset(0x0000'0001'0000'0000), 8);
    EXPECT_EQ(_linear_block_offset(0x0000'0002'0000'0000), 16);
    EXPECT_EQ(_linear_block_offset(0x0000'0020'0000'0000), 256);
    for (uint64_t bits = 1; bits <= 32; ++bits) {
        uint64_t msh = Utils::RandomValue<uint64_t>();
        msh &= 0x0000'0000'ffff'ffff;
        const uint64_t size = (uint64_t(1) << bits) - 1;
        msh |= size << 32;
        EXPECT_EQ(_linear_block_offset(msh), size * 8) << LinearUtils::MshToString(msh);
    }
}

TEST_F(LinearTest, block_size) {
    EXPECT_EQ(_linear_block_size(0x0000'0000'0000'0000), 0);
    EXPECT_EQ(_linear_block_size(0x0000'0000'0000'0001), 8);
    EXPECT_EQ(_linear_block_size(0x0000'0000'0000'0002), 16);
    EXPECT_EQ(_linear_block_size(0x0000'0000'0000'0020), 256);
    for (uint64_t bits = 1; bits <= 32; ++bits) {
        uint64_t msh = Utils::RandomValue<uint64_t>();
        msh &= 0xffff'ffff'0000'0000;
        const uint64_t size = (uint64_t(1) << bits) - 1;
        msh |= size;
        EXPECT_EQ(_linear_block_size(msh), size * 8) << LinearUtils::MshToString(msh);
    }
}

}
}
