// vim: set ft=rb:
package lexah;

import mcli.Dispatch;
import lexah.cli.Cli;

using Lambda;
using StringTools;

class Main{

public static function main(){
    var args = Sys.args();
    Sys.setCwd(args.pop());
 new     Dispatch(args).dispatch( new Cli());
};

}