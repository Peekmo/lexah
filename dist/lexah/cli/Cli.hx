// vim: set ft=rb:
package lexah.cli;
using Lambda;
using StringTools;


import mcli.CommandLine;
import sys.FileSystem;
import lexah.tools.Error;

/**
     _                  _
    | |                | |
    | | ____ _   _ ____| | _
    | |/ _  | \ / ) _  | || \
    | ( (/ / ) X ( ( | | | | |
    |_|\____|_/ \_)_||_|_| |_|

    Lexah 0.0.1 - https://github.com/Peekmo/lexah
**/
class Cli extends CommandLine{

public static inline var ERROR_TYPE = "transpile_error";

/**
    Source directory or file
    @alias s
**/
public var src: String;

/**
    Destination directory or file
    @alias d
**/
public var dest: String;

/**
    Execute the command when source file(s) are changed
    @alias w
**/
public var watch: Bool;

/**
    Copy only lexah files to dest directory
**/
public var lexahOnly: Bool;

/**
    Show this message
    @alias h
**/
public function help() : Void{
    Sys.println(this.showUsage());
    Sys.exit(0);
}

private function transpile() : Void{
    if( this.src != null ) {
        if( !FileSystem.exists(this.src) ) {
            Error.create(Cli.ERROR_TYPE, "Source not found");
        }

        var transpiler = new  TranspilerCommand(this.src, this.dest);
        while( true ) {
            try {
                if( transpiler.transpile(this.lexahOnly) &&
                    transpiler.response != null &&
                    transpiler.response != "" ) {
                    Sys.println(transpiler.response);
                }else{
                    Sys.println("Transpilation done.");
                }

            } catch( err: String){
                Sys.println(err);
            }

            if( !this.watch ) {
                break;
            }
        }
    }
}

public function runDefault() : Void{
    try {
        if( this.src != null ) {
            this.transpile();
        }else{
            this.help();
        }
    } catch( err:String){
        Sys.println(err);
        Sys.exit(0);
    }
}

}