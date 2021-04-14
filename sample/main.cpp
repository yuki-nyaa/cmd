#include<yuki/cmd.h>
#include"cmd.h"
int main(int argc,char** argv){
    yuki::Cmd_Lexer cmd_lexer(std::move(xxx::opt_table),xxx::cmd_impl::open);
    yuki::Cmd_Lexer cmd_lexer2(std::move(xxx::opt_table2),xxx::cmd_impl2::open);
    cmd_lexer.process(xxx::data_sample,argc,argv);
    cmd_lexer2.process(xxx::data_sample,argc,argv);
}