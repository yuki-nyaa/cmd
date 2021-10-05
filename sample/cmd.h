#include<string>
#include<yuki/cmd.hpp>
namespace xxx{
struct Cmd_Data{
    std::string filename;
};
struct Cmd_Data2{
    std::string filename;
};
inline Cmd_Data data_sample;
inline Cmd_Data2 data2_sample;

extern yuki::cmd_opt_table_t<Cmd_Data> opt_table;
extern yuki::cmd_opt_table_t<Cmd_Data2> opt_table2;

namespace cmd_impl{
    typedef yuki::cmd_first_impl_t<Cmd_Data> cmd_first_impl_t;
    cmd_first_impl_t open;
    cmd_first_impl_t version;
}
namespace cmd_impl2{
    typedef yuki::cmd_first_impl_t<Cmd_Data2> cmd_first_impl_t;
    cmd_first_impl_t open;
    cmd_first_impl_t version;
}
}