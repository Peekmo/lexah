// vim: set ft=rb:
package lexah;
using Lambda;
using StringTools;


import mcli.Dispatch;
import lexah.cli.Cli;

class Main{

public static function main(){
    var args = Sys.args();
    Sys.setCwd(args.pop());
 new     Dispatch(args).dispatch( new Cli());
}

}