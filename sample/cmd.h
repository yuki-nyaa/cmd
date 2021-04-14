#include<string>
#include<yuki/cmd.h>
namespace xxx{
struct Cmd_Data : yuki::Cmd_Data_Base{
    std::string filename;
};
struct Cmd_Data2 : yuki::Cmd_Data_Base{
    std::string filename;
};
inline Cmd_Data data_sample;
inline Cmd_Data2 data2_sample;

extern yuki::cmd_opt_table_t opt_table;
extern yuki::cmd_opt_table_t opt_table2;

namespace cmd_impl{
    yuki::cmd_first_impl_t open;
    yuki::cmd_impl_t version;
}
namespace cmd_impl2{
    yuki::cmd_first_impl_t open;
    yuki::cmd_impl_t version;
}
}