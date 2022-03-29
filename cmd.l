%option fast unicode nodefault noline
%option outfile="cmd.hpp"
%option namespace="yuki" prefix="yuki_cmd" lexer="Cmd_Lexer" lex="lex" token-type="yuki::Cmd_Token" templated_lexer="Cmd_Lexer<Cmd_Data_t>"

%code_templateclass{
    template<typename Cmd_Data_t>
}

%code_cpptop{
#pragma once
#include<string>
#include<yuki/vector.hpp>
#include<unordered_map>
#include<fmt/core.h>
#ifndef YUKI_CMD_ARG_RESERVE
#define YUKI_CMD_ARG_RESERVE 8
#endif
namespace yuki{
    enum struct Cmd_Token : unsigned char {FIRST,L,Sa,Sb,Sc,ARG,END,ERR_UNKNOWN_S,NIL,};

    template<typename Cmd_Data_t>
    using cmd_impl_t = void(Cmd_Data_t&,yuki::Vector<std::string>&);
    template<typename Cmd_Data_t>
    using cmd_first_impl_t = void(Cmd_Data_t&,std::string&);

    template<typename Cmd_Data_t>
    struct Cmd_Opt_Propt{
        Cmd_Token cat; // Option category
        typedef unsigned short arg_size_t;
        arg_size_t min; // Minimum number of arguments
        arg_size_t max; // Maximum number of arguments
        static constexpr arg_size_t ARG_SIZE_MAX = std::numeric_limits<arg_size_t>::max();
        cmd_impl_t<Cmd_Data_t>* impl; // Pointer to the function which does the actual work.
    };

    template<typename Cmd_Data_t>
    using cmd_opt_table_t = std::unordered_map<std::string,Cmd_Opt_Propt<Cmd_Data_t>>;
}
}

%code_class{
  public:
    typedef cmd_opt_table_t<Cmd_Data_t> cmd_opt_table_t;
    typedef cmd_first_impl_t<Cmd_Data_t> cmd_first_impl_t;

    Cmd_Lexer(cmd_opt_table_t&& opt_table_p,cmd_first_impl_t* first_p=nullptr,const reflex::Input& input=reflex::Input(),std::ostream& os=std::cout) : AbstractBaseLexer(input, os),opt_table(std::move(opt_table_p)),first_(first_p) {}

    void process(Cmd_Data_t& data, int argc, char** argv);

    template<typename... Args>
    static void print_error_ycmd(FILE* fp,std::string_view format,const Args&... args){
        fprintf(fp,"YCMD_ERROR: ");
        fmt::vprint(fp,format,fmt::make_format_args(args...));
        fflush(fp);
    }
  private:
    const cmd_opt_table_t opt_table;
    cmd_first_impl_t* first_=nullptr;
    bool first_encountered=false; // True if the first option is already processed.
    std::string semantic_str;
}

%x FIRST LONG SHORT ARG ARG_S SKIP_EQ

ne    [^=]

%%
/* Command line option categories:
 *   1: Long option, which starts with "--" (double hyphen-minus(U+002D)), and does not contain the equality character "=". Can have an arbitrary number of arguments. The first argument can be specified by a SINGLE "=", e.g. "--foo=bar".
 *   2: Short option, consisting of a single character (other than "="), preceded by "-" (single hyphen-minus). However, that the option ITSELF consists of a single character does not mean that only one character can follow "-". Depending on how the parser handles later characters, this category can be further divided into the following sub-categories:
 *     a: The parser recognizes each later character as a short option. E.g. "-abc" has the same effect as "-a -b -c", provided that "b" and "c" are also of this sub-category. Naturally, for such expressions to make sense, each of these options must have no argument, or all arguments have a default value.
 *     b: The parser recognizes the entire string following the main option character as the first argument to this option. E.g. "-Wall", in which "all" is recognized as the first argument to the short option "-W".
 *     c: The parser recognizes each single character following the main option character as an argument. E.g. "-Abc", in which the short option "-A" has two arguments, namely "b" and "c". Note that "-A bc" would have a different effect because the parser takes all character at once when parsing stand-alone arguments. Such options are rarely used.
 *   3: The first option, which does not require any special starting character. Usually used for filenames. Must be placed in the FIRST position and take no arguments. All strings that occur in later positions but does not begin with either "-" or "--" are recognized as arguments for the previous long/short option.
 */
<INITIAL>{
--    {first_encountered=true; start(LONG);}
-    {first_encountered=true; start(SHORT);}
<<DEFAULT>>    {
    if(first_encountered){
        start(ARG);
    }else{
        first_encountered=true;
        start(FIRST);
    }
}
}

<FIRST>{
.+    {semantic_str=str(); start(INITIAL); return Cmd_Token::FIRST;}
}

<LONG>{
{ne}+(?==)    {semantic_str=str(); start(SKIP_EQ); return Cmd_Token::L;}
{ne}+    {semantic_str=str(); start(INITIAL); return Cmd_Token::L;}
=.*    {print_error_ycmd(stderr,"you can't start an option with \"=\"!\n"); start(INITIAL);}
}

<SHORT>{
=    {start(ARG);}
.    {
    semantic_str=str();
    try{
        switch(opt_table.at(semantic_str).cat){
            case Cmd_Token::Sa: {start(SHORT); return Cmd_Token::Sa;}
            case Cmd_Token::Sb: {start(ARG); return Cmd_Token::Sb;}
            case Cmd_Token::Sc: {start(ARG_S); return Cmd_Token::Sc;}
        }
    }catch(const std::out_of_range& e){ // No option with the given name.
        start(SHORT);
        return Cmd_Token::ERR_UNKNOWN_S;
    }
}
}

<ARG>{
.+    {semantic_str=str(); start(INITIAL); return Cmd_Token::ARG;}
}

<ARG_S>{
.    {semantic_str=str(); start(ARG_S); return Cmd_Token::ARG;}
}

<SKIP_EQ>{
=    {start(ARG);}
}

<*><<EOF>>    {start(INITIAL); return Cmd_Token::END;}

%%
#include<vector>
#include<fmt/core.h>
#include<yuki/print.hpp>
template<typename Cmd_Data_t>
void yuki::Cmd_Lexer<Cmd_Data_t>::process(Cmd_Data_t& cmd_data, const int argc, char** argv){
    if(argc>1){
        Cmd_Token token_ahead=Cmd_Token::NIL;
        std::string f_name;
        yuki::Vector<std::string> args(yuki::reserve_tag,YUKI_CMD_ARG_RESERVE);
        bool stall=false;

        for(int i=1; i<=argc-1; ++i){
            this->in(argv[i]);
            bool end_reached=false;
            while(!end_reached){
                if(stall==false)
                    token_ahead=this->lex();
                if(token_ahead==Cmd_Token::END && i<argc-1){
                    end_reached=true;
                    continue;
                }
                switch(token_ahead){
                    case Cmd_Token::FIRST :{
                        if(this->first_)
                            this->first_(cmd_data,this->semantic_str);
                        else
                            print_error_ycmd(stderr,"\"first\" function not defined!\n");
                        break;
                    }
                    case Cmd_Token::L : case Cmd_Token::Sa : case Cmd_Token::Sb : case Cmd_Token::Sc :{
                        if(f_name.empty()){
                            stall=false;
                            f_name=std::move(this->semantic_str);
                        }else{ // Collected enough arguments.
                            try{
                                if(args.size()<=this->opt_table.at(f_name).max && args.size()>=this->opt_table.at(f_name).min){
                                    this->opt_table.at(f_name).impl(cmd_data,args);
                                }else{ // Argument number does not match. Discard the whole series.
                                    print_error_ycmd(stderr,"argument number dismatch!\n");
                                    yuki::print_note(stderr,"the option \"{}\" requires argument number between {} and {}, but you have supplied {}.\n",f_name,this->opt_table.at(f_name).min,this->opt_table.at(f_name).min,args.size());
                                }
                            }catch(const std::out_of_range& e){ // No option with the given name.
                                print_error_ycmd(stderr,"unknown option: {}\n",f_name);
                            }
                            stall=true;
                            args.clear();
                            f_name.clear();
                        }
                        break;
                    }
                    case Cmd_Token::ERR_UNKNOWN_S :{ // Largely the same as the previous case.
                        // The variable `stall` does not change in this case because this short option is discarded anyway.
                        if(f_name.empty()){
                            print_error_ycmd(stderr,"unknown option: {}\n",this->semantic_str); // Diff!
                        }else{ // Collected enough arguments.
                            try{
                                if(args.size()<=this->opt_table.at(f_name).max && args.size()>=this->opt_table.at(f_name).min){
                                    this->opt_table.at(f_name).impl(cmd_data,args);
                                }else{ // Argument number does not match. Discard the whole series.
                                    print_error_ycmd(stderr,"argument number dismatch!\n");
                                    yuki::print_note(stderr,"the option \"{}\" requires argument number between {} and {}, but you have supplied {}.\n",f_name,this->opt_table.at(f_name).min,this->opt_table.at(f_name).min,args.size());
                                }
                            }catch(const std::out_of_range& e){ // No option with the given name.
                                print_error_ycmd(stderr,"unknown option: {}\n",f_name);
                            }
                            args.clear();
                            f_name.clear();
                            print_error_ycmd(stderr,"unknown option: {}\n",this->semantic_str); // Diff 2 !
                        }
                        break;
                    }
                    case Cmd_Token::ARG :{
                        if(!f_name.empty()){
                            args.emplace_back(std::move(this->semantic_str));
                        }else{ // Encountered an argument without an option at hand.
                            print_error_ycmd(stderr,"argument encountered not scanning arguments!!\n");
                            yuki::print_note(stderr,"argument: {}\n",this->semantic_str);
                            yuki::print_note(stderr,"{}did you forget to start an option with \"--\" or \"-\"?\n");
                        }
                        break;
                    }
                    case Cmd_Token::END :{ // The last shipout.
                        if(!f_name.empty()){
                            try{
                                if(args.size()<=this->opt_table.at(f_name).max && args.size()>=this->opt_table.at(f_name).min){
                                    this->opt_table.at(f_name).impl(cmd_data,args);
                                }else{ // Argument number does not match. Discard the whole series.
                                   print_error_ycmd(stderr,"argument number dismatch!\n");
                                    yuki::print_note(stderr,"the option \"{}\" requires argument number between {} and {}, but you have supplied {}.\n",f_name,this->opt_table.at(f_name).min,this->opt_table.at(f_name).min,args.size());
                                }
                            }catch(const std::out_of_range& e){ // No option with the given name.
                                print_error_ycmd(stderr,"unknown option: {}\n",f_name);
                            }
                        }
                        end_reached=true;
                        continue;
                    }
                }
            }
        }
    }
}