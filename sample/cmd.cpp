#include"cconfig"
#include<fmt/core.h>
#include<yuki/cmd.h>
#include"cmd.h"
namespace xxx{
namespace cmd_impl{
    void open(yuki::Cmd_Data_Base& cmd_data_base,std::string& filename){
        Cmd_Data& cmd_data=static_cast<Cmd_Data&>(cmd_data_base);
        cmd_data.filename=filename;
        fmt::print(stdout,"filename: {}\n",cmd_data.filename);
    }
    void version(yuki::Cmd_Data_Base&,std::vector<std::string>&){
        fmt::print(stdout,"yuki.cmd.sample version {}.{}\n",YUKI_CMD_SAMPLE_VERSION_MAJOR,YUKI_CMD_SAMPLE_VERSION_MINOR);
    }
}
yuki::cmd_opt_table_t opt_table={ // Option property table
    {"version",{yuki::Cmd_Token::L, 0, 0, &cmd_impl::version}},
    {"v",{yuki::Cmd_Token::Sa, 0, 0, &cmd_impl::version}},
};


namespace cmd_impl2{
    void open(yuki::Cmd_Data_Base& cmd_data_base,std::string& filename){
        Cmd_Data2& cmd_data2=static_cast<Cmd_Data2&>(cmd_data_base);
        cmd_data2.filename=filename;
        cmd_data2.filename.append("(another)");
        fmt::print(stdout,"filename(another): {}\n",cmd_data2.filename);
    }
    void version(yuki::Cmd_Data_Base&,std::vector<std::string>&){
        fmt::print(stdout,"yuki.cmd.sample version {}.{} (another)\n",YUKI_CMD_SAMPLE_VERSION_MAJOR,YUKI_CMD_SAMPLE_VERSION_MINOR);
    }
}
yuki::cmd_opt_table_t opt_table2={ // Option property table
    {"version2",{yuki::Cmd_Token::L, 0, 0, &cmd_impl2::version}},
    {"v",{yuki::Cmd_Token::Sa, 0, 0, &cmd_impl2::version}},
};
}